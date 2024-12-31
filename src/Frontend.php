<?php

declare(strict_types=1);

namespace Dotclear\Plugin\FrontendSession;

use Dotclear\App;
use Dotclear\Core\Process;
use Dotclear\Helper\L10n;
use Dotclear\Helper\Network\Http;

/**
 * @brief       FrontendSession module frontend process.
 * @ingroup     FrontendSession
 *
 * @author      Jean-Christian Paul Denis
 * @copyright   AGPL-3.0
 */
class Frontend extends Process
{
    public static function init(): bool
    {
        return self::status(My::checkContext(My::FRONTEND));
    }

    public static function process(): bool
    {
        if (!self::status() || !My::settings()->get('active')) {
            return false;
        }

        // locales in public file
        l10n::set(dirname(__DIR__) . '/locales/' . App::lang()->getLang() . '/public');

        // template values and block
        App::frontend()->template()->addValue('FrontendSessionID', [FrontendTemplate::class, 'FrontendSessionID']);
        App::frontend()->template()->addValue('FrontendSessionUrl', [FrontendTemplate::class, 'FrontendSessionUrl']);
        App::frontend()->template()->addValue('FrontendSessionConnected', [FrontendTemplate::class, 'FrontendSessionConnected']);
        App::frontend()->template()->addValue('FrontendSessionDisconnected', [FrontendTemplate::class, 'FrontendSessionDisconnected']);
        App::frontend()->template()->addBlock('FrontendSessionIsAuth', [FrontendTemplate::class, 'FrontendSessionIsAuth']);
        App::frontend()->template()->addValue('FrontendSessionDisplayName', [FrontendTemplate::class, 'FrontendSessionDisplayName']);

        // behaviors
        App::behavior()->addBehaviors([
            // public widgets
            'initWidgets'      => [Widgets::class, 'initWidgets'],
        ]);

        self::doAuthControl();

        return true;
    }

    /**
     * Chek user rights and cookies.
     */
    private static function doAuthControl(): void
    {
        if (!My::settings()->get('active')) {
            return;
        }

        App::frontend()->context()->form_error = $user_id = $user_pwd = $user_key = null;

        // HTTP/1.1
        //header('Expires: Mon, 26 Jul 1997 05:00:00 GMT');
        //header('Cache-Control: no-store, no-cache, must-revalidate, post-check=0, pre-check=0');

        // if we have POST login information, go throug auth process
        if (!empty($_POST[My::id() . '_login']) && !empty($_POST[My::id() . '_password'])) {
            $user_id  = $_POST[My::id() . '_login'];
            $user_pwd = $_POST[My::id() . '_password'];
        }
        // if we have COOKIE information, go throug auth process
        elseif (isset($_COOKIE[My::id()]) && strlen($_COOKIE[My::id()]) == 104) {
            # If we have a cookie, go through auth process with user_key
            $user_id = substr($_COOKIE[My::id()], 40);
            $user_id = @unpack('a32', @pack('H*', $user_id));
            if (is_array($user_id)) {
                $user_id  = trim($user_id[1]);
                $user_key = substr($_COOKIE[My::id()], 0, 40);
                $user_pwd = null;
            } else {
                $user_id = null;
            }
        }
        // no COOKIE nor POST login and password information
        elseif (!empty($_POST[My::id() . '_login']) || !empty($_POST[My::id() . '_password'])) {
            App::frontend()->context()->form_error = __("Error: your password may be wrong or you haven't an account or you haven't ask for its activation.");
        }

        if ($user_id !== null && ($user_pwd !== null || $user_key !== null)) {
            // we check the user and its perm
            if (App::auth()->checkUser($user_id, $user_pwd, $user_key, false) === true
             && App::auth()->check(My::id(), App::blog()->id()) === true
            ) {
                if ($user_key === null) {
                    $cookie_console = Http::browserUID(
                        App::config()->masterKey() .
                        $user_id .
                        App::auth()->cryptLegacy($user_id)
                    ) . bin2hex(pack('a32', $user_id));
                } else {
                    $cookie_console = $_COOKIE[My::id()];
                }
                setcookie(My::id(), $cookie_console, strtotime('+20 hours'), '/', '', self::useSSL());
            } else {
                //App::frontend()->context()->form_error = __("Error: your password may be wrong or you haven't an account or you haven't ask for its activation.");

                if (isset($_COOKIE[My::id()])) {
                    unset($_COOKIE[My::id()]);
                    setcookie(My::id(), '', time() - 3600, '/', '', self::useSSL());
                }
                // need to replay doAuthControl() to remove user information from Auth if it exists but have no permissions
                Http::redirect(Http::getSelfURI());
            }
        }
    }

    /**
     * Check SSL.
     */
    public static function useSSL(): bool
    {
        $bits = parse_url(App::blog()->url());

        if (empty($bits['scheme']) || !preg_match('%^http[s]?$%', $bits['scheme'])) {
            return false;
        }

        return $bits['scheme'] == 'https';
    }
}

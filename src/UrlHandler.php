<?php

declare(strict_types=1);

namespace Dotclear\Plugin\FrontendSession;

use ArrayObject;
use Dotclear\App;
use Dotclear\Core\Frontend\Url;
use Dotclear\Core\Frontend\Utility;
use Dotclear\Helper\File\Path;
use Dotclear\Helper\Html\Html;
use Dotclear\Helper\Network\Http;
use Dotclear\Helper\Text;
use Exception;

/**
 * @brief       FrontendSession module URL handler.
 * @ingroup     FrontendSession
 *
 * @author      Jean-Christian Paul Denis
 * @copyright   AGPL-3.0
 */
class UrlHandler extends Url
{
    /**
     * Session login endpoint
     */
    public static function sessionLogin(?string $args): void
    {
        if (!My::settings()->get('active')) {
            self::p404();
        }

        //self::doAuthControl();

        if (!is_null($args)) {
            $args = substr($args, 1);
            $args = explode('/', $args);
        }

        // logout
        if (is_array($args) && $args[0] == 'logout') {
            // Unset cookie if necessary
            if (isset($_COOKIE[My::id()])) {
                unset($_COOKIE[My::id()]);
                setcookie(My::id(), '', time() - 3600, '/', '', Frontend::useSSL());
            }
            App::blog()->triggerBlog();

            Http::redirect(App::blog()->url());
        // no loggin session, go to login page
        } elseif (App::auth()->userID() == '') {
            self::serveTemplate(My::id() . '.html');
        } else {
            self::serveTemplate(My::id() . '.html');
            //self::p404();
        }
    }

    /**
     * Serve template.
     */
    private static function serveTemplate(string $tpl): void
    {
        // use only dotty tplset
        $tplset = App::themes()->moduleInfo(App::blog()->settings()->get('system')->get('theme'), 'tplset');
        if ($tplset != 'dotty') {
            self::p404();
        }

        $default_template = Path::real(App::plugins()->moduleInfo(My::id(), 'root')) . DIRECTORY_SEPARATOR . Utility::TPL_ROOT . DIRECTORY_SEPARATOR;
        if (is_dir($default_template . $tplset)) {
            App::frontend()->template()->setPath(App::frontend()->template()->getPath(), $default_template . $tplset);
        }

        self::serveDocument($tpl);
    }
}

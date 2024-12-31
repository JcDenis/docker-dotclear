<?php

declare(strict_types=1);

namespace Dotclear\Plugin\FrontendSession;

use ArrayObject;
use Dotclear\App;
use Dotclear\Core\Frontend\Tpl;

/**
 * @brief       FrontendSession module template specifics.
 * @ingroup     FrontendSession
 *
 * @author      Jean-Christian Paul Denis
 * @copyright   AGPL-3.0
 */
class FrontendTemplate
{
    /**
     * Generic filter helper.
     *
     * @param   ArrayObject<string, mixed>  $attr       The attributes
     */
    private static function filter(ArrayObject $attr, string $res): string
    {
        return '<?php echo ' . sprintf(App::frontend()->template()->getFilters($attr), $res) . '; ?>';
    }

    /**
     * Get module ID.
     *
     * @param   ArrayObject<string, mixed>  $attr       The attributes
     */
    public static function FrontendSessionID(ArrayObject $attr): string
    {
        return self::filter($attr, My::class . '::id()');
    }

    /**
     * Get session page URL.
     *
     * @param   ArrayObject<string, mixed>  $attr       The attributes
     */
    public static function FrontendSessionUrl(ArrayObject $attr): string
    {
        return self::filter($attr, 'App::blog()->url().App::url()->getURLFor(' . My::class . '::id())' . (!empty($attr['logout']) ? ".'/logout'" : ''));
    }

    /**
     * Get session page text when user is connected.
     *
     * @param   ArrayObject<string, mixed>  $attr       The attributes
     */
    public static function FrontendSessionConnected(ArrayObject $attr): string
    {
        return self::filter($attr, My::class . '::settings()->get(\'connected\')');
    }

    /**
     * Get session page text when user is disconnected.
     *
     * @param   ArrayObject<string, mixed>  $attr       The attributes
     */
    public static function FrontendSessionDisconnected(ArrayObject $attr): string
    {
        return self::filter($attr, My::class . '::settings()->get(\'disconnected\')');
    }

    /**
     * Check if user is authenticate.
     *
     * @param   ArrayObject<string, mixed>  $attr       The attributes
     */
    public static function FrontendSessionIsAuth(ArrayObject $attr, string $content): string
    {
        $if = 'App::auth()->userID()';

        if (isset($attr['true'])) {
            $sign = (bool) $attr['true'] ? '' : '!';
            $if   = $sign . '(' . $if . ')';
        }

        return '<?php if(' . $if . ') : ?>' . $content . '<?php endif; ?>';
    }

    /**
     * Get user display name.
     *
     * @param   ArrayObject<string, mixed>  $attr       The attributes
     */
    public static function FrontendSessionDisplayName(ArrayObject $attr): string
    {
        return self::filter($attr, '(App::auth()->userID() != \'\' ? App::auth()->getInfo(\'user_cn\') : \'\')');
    }
}

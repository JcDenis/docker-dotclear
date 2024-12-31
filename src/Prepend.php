<?php

declare(strict_types=1);

namespace Dotclear\Plugin\FrontendSession;

use Dotclear\App;
use Dotclear\Core\PostType;
use Dotclear\Core\Process;
use Dotclear\Database\MetaRecord;

/**
 * @brief       FrontendSession module prepend.
 * @ingroup     FrontendSession
 *
 * @author      Jean-Christian Paul Denis
 * @copyright   AGPL-3.0
 */
class Prepend extends Process
{
    public static function init(): bool
    {
        return self::status(My::checkContext(My::PREPEND));
    }

    public static function process(): bool
    {
        if (!self::status()) {
            return false;
        }

        // contributor permission
        App::auth()->setPermissionType(
            My::id(),
            My::name() . ':' . __('Frontend')
        );

        // add session login URL
        App::url()->register(
            My::id(),
            'session/login',
            '^session/login(/.+)?$',
            [UrlHandler::class, 'sessionLogin']
        );

        return true;
    }
}

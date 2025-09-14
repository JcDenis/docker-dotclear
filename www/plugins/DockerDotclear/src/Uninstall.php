<?php

declare(strict_types=1);

namespace Dotclear\Plugin\DockerDotclear;

use Dotclear\Helper\Process\TraitProcess;
use Dotclear\Plugin\Uninstaller\Uninstaller;

/**
 * @brief       The module uninstall class.
 * @ingroup     DockerDotclear
 *
 * @copyright   Jean-Christian Paul Denis
 * @copyright   AGPL-3.0
 */
class Uninstall
{
    use TraitProcess;

    public static function init(): bool
    {
        return self::status(My::checkContext(My::UNINSTALL));
    }

    public static function process(): bool
    {
        if (!self::status()) {
            return false;
        }

        Uninstaller::instance()
            ->addUserAction(
                'settings',
                'delete_all',
                My::id()
            )
            ->addUserAction(
                'plugins',
                'delete',
                My::id()
            )
            ->addUserAction(
                'versions',
                'delete',
                My::id()
            )

            ->addDirectAction(
                'plugins',
                'delete',
                My::id()
            )
            ->addDirectAction(
                'versions',
                'delete',
                My::id()
            )
        ;

        return false;
    }
}

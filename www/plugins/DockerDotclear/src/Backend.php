<?php

declare(strict_types=1);

namespace Dotclear\Plugin\DockerDotclear;

use Dotclear\App;
use Dotclear\Core\Process;
use Dotclear\Database\Cursor;
use Dotclear\Interface\Core\BlogSettingsInterface;
use Dotclear\Helper\File\Files;

/**
 * @brief   The module backend process.
 * @ingroup DockerDotclear
 *
 * @copyright   Jean-Christian Paul Denis
 * @copyright   AGPL-3.0
 */
class Backend extends Process
{
    public static function init(): bool
    {
        return self::status(My::checkContext(My::BACKEND));
    }

    public static function process(): bool
    {
        if (!self::status()) {
            return false;
        }

        # Fix blog public path on blog creation
        App::behavior()->addBehaviors([
            'adminAfterBlogCreate' => function (Cursor $cur, string $blog_id, BlogSettingsInterface $blog_settings) {
                Files::makeDir(My::settings()->get('public_root') . '/' . $blog_id, true);
                $blog_settings->system->put('public_path', My::settings()->get('public_root') . '/' . $blog_id);
                $blog_settings->system->put('public_url', '/' . $blog_id . '/public');
            },
        ]);

        return true;
    }
}

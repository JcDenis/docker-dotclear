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

        # Fix blog paths on blog creation
        App::behavior()->addBehaviors([
            'adminAfterBlogCreate' => function (Cursor $cur, string $blog_id, BlogSettingsInterface $blog_settings) {
                Files::makeDir(My::settings()->get('public_root') . '/' . $blog_id, true);
                $blog_settings->system->put('public_path', My::settings()->get('public_root') . '/' . $blog_id);
                $blog_settings->system->put('public_url', (str_ends_with($cur->blog_url, $cur->blog_id . '/') ? '/' . $blog_id : '') . '/public');
                $blog_settings->system->put('themes_path', My::settings()->get('themes_root'));
                $blog_settings->system->put('themes_url', '/themes');
            },
        ]);

        return true;
    }
}

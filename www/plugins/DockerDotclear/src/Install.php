<?php

declare(strict_types=1);

namespace Dotclear\Plugin\DockerDotclear;

use Dotclear\App;
use Dotclear\Database\Statement\UpdateStatement;
use Dotclear\Helper\Network\Http;
use Dotclear\Helper\Process\TraitProcess;
use Exception;

/**
 * @brief       The module install process.
 * @ingroup     DockerDotclear
 *
 * @copyright   Jean-Christian Paul Denis
 * @copyright   AGPL-3.0
 */
class Install
{
    use TraitProcess;

    public static function init(): bool
    {
        return self::status(My::checkContext(My::INSTALL));
    }

    public static function process(): bool
    {
        if (!self::status()) {
            return false;
        }

        try {
            # Set module setting
            My::settings()->put('public_root', My::DOCKER_DOTCLEAR_PUBLIC_ROOT, 'string', 'Blogs public root path', false, true);
            My::settings()->put('themes_root', My::DOCKER_DOTCLEAR_THEMES_ROOT, 'string', 'Blogs themes root path', false, true);

            # On first install, update default blog parameters
            if (App::version()->getVersion(My::id()) === '') {
                $blog_id = 'default';

                # Fix default blog paths
                $blog_settings = App::blogSettings()->createFromBlog($blog_id);
                $blog_settings->get('system')->put('public_path', My::DOCKER_DOTCLEAR_PUBLIC_ROOT . '/' . $blog_id);
                $blog_settings->get('system')->put('public_url', '/' . $blog_id . '/public');
                $blog_settings->get('system')->put('themes_path', My::DOCKER_DOTCLEAR_THEMES_ROOT);
                $blog_settings->get('system')->put('themes_url', '/themes');
                $blog_settings->get('system')->put('url_scan', 'path_info');

                # Fix default blog URL
                $host = Http::getHost();
                if (is_string(parse_url($host, PHP_URL_HOST))) {
                    // From web install
                    $blog_url = $host . '/' . $blog_id . '/';
                } else {
                    // From command line install, host is unknown: keep given URL in path info mode
                    $blog_url = (string) App::blogs()->getBlog($blog_id)->f('blog_url');
                    $blog_url = rtrim((string) preg_replace('#/?index\.php\?$#', '', $blog_url), '/') . '/';
                }
                $cur           = App::blog()->openBlogCursor();
                $cur->blog_url = $blog_url;
                $sql           = new UpdateStatement();
                $sql
                    ->where('blog_id ' . $sql->in($blog_id))
                    ->update($cur);
            }

            return true;
        } catch (Exception $e) {
            App::error()->add($e->getMessage());

            return false;
        }
    }
}

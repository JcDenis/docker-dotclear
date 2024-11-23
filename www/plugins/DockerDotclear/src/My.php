<?php

declare(strict_types=1);

namespace Dotclear\Plugin\DockerDotclear;

use Dotclear\Module\MyPlugin;

/**
 * @brief   The module helper.
 * @ingroup DockerDotclear
 *
 * @copyright   Jean-Christian Paul Denis
 * @copyright   AGPL-3.0
 */
class My extends MyPlugin
{
    /**
     * Blogs default public root path.
     *
     * @var     string  DOCKER_DOTCLEAR_PUBLIC_ROOT
     */
    public const DOCKER_DOTCLEAR_PUBLIC_ROOT = '/var/www/dotclear/blogs';

    /**
     * Blogs default themes root path.
     *
     * Themes are common to all blogs.
     *
     * @var     string  DOCKER_DOTCLEAR_THEMES_ROOT
     */
    public const DOCKER_DOTCLEAR_THEMES_ROOT = '/var/www/dotclear/themes';

    // Use default permissions
}

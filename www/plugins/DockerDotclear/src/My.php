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

    // Use default permissions
}

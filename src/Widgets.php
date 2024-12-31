<?php

declare(strict_types=1);

namespace Dotclear\Plugin\FrontendSession;

use Dotclear\App;
use Dotclear\Database\MetaRecord;
use Dotclear\Helper\Html\Form\Hidden;
use Dotclear\Helper\Html\Html;
use Dotclear\Plugin\widgets\Widgets as dcWidgets;
use Dotclear\Plugin\widgets\WidgetsElement;
use Dotclear\Plugin\widgets\WidgetsStack;

/**
 * @brief       FrontendSession module widgets helper.
 * @ingroup     FrontendSession
 *
 * @author      Jean-Christian Paul Denis
 * @copyright   AGPL-3.0
 */
class Widgets
{
    /**
     * Initializes module widget.
     */
    public static function initWidgets(WidgetsStack $widgets): void
    {
        $widgets
            ->create(
                'FrontendSession',
                __('Frontend session'),
                [self::class, 'FrontendSessionWidget'],
                null,
                'Public login form'
            )
            ->addTitle(__('Login'))
            ->addContentOnly()
            ->addClass()
            ->addOffline();
    }

    /**
     * Widget public rendering helper for public login and menu.
     */
    public static function FrontendSessionWidget(WidgetsElement $widget): string
    {
        if ($widget->isOffline() || !My::settings()->get('active')) {
            return '';
        }

        $url = App::blog()->url() . App::url()->getURLFor(My::id());
        $res = $widget->renderTitle($widget->get('title'));

        if (App::auth()->userID()) {
            $res .= '<p>' . __('Welcome') . ' ' . App::auth()->getInfo('user_cn') .
                '<ul><li><a href="' . $url . '/logout">' . __('Logout') . '</a></li></ul>';
        } else {
            $res .= '<form method="post" name="' . My::id() . '_form" id="' . My::id() . '_widget_form" action="">';
            if (App::frontend()->context()->form_error !== null) {
                $res .= '<p class="erreur">' . Html::escapeHTML(App::frontend()->context()->form_error) . '</p>';
            }
            $res .= '<p>' .
                    '<label for="' . My::id() . '_login" class="required">' . __('Login:') . '</label><br />' .
                    '<input type="text" id="' . My::id() . '_widget_login" name="' . My::id() . '_login" value="" />' .
                '</p>' .
                '<p>' .
                    '<label for="' . My::id() . '_password" class="required">' . __('Password:') . '</label><br />' .
                    '<input type="password" id="' . My::id() . '_widget_password" name="' . My::id() . '_password" value="" />' .
                '</p>' .
                '<p>' .
                    '<input class="submit" type="submit" id="' . My::id() . '_widget_submit" name="' . My::id() . '_submit" value="' . __('Connect') . '" />' .
                '</p>' .
                '</form>';
        }

        return $widget->renderDiv((bool) $widget->get('content_only'), My::id() . ' ' . $widget->get('class'), '', $res);
    }
}

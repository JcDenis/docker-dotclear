<?php

declare(strict_types=1);

namespace Dotclear\Plugin\FrontendSession;

use ArrayObject;
use Dotclear\App;
use Dotclear\Core\Process;
use Dotclear\Helper\Html\Form\{
    Checkbox,
    Div,
    Label,
    Para,
    Text,
    Textarea
};
use Dotclear\Helper\Html\Html;
use Dotclear\Interface\Core\BlogSettingsInterface;

/**
 * @brief       FrontendSession backend class.
 * @ingroup     FrontendSession
 *
 * @author      Jean-Christian Paul Denis
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

        App::behavior()->addBehaviors([
            // widget
            'initWidgets'                => Widgets::initWidgets(...),
            // blog settings form
            'adminBlogPreferencesFormV2' => function (BlogSettingsInterface $blog_settings): void {
                echo (new Div())
                    ->class('fieldset')
                    ->items([
                        (new Text('h4', My::name()))
                            ->id(My::id() . '_params'),
                        (new Para())
                            ->items([
                                (new Checkbox(My::id() . 'active', (bool) $blog_settings->get(My::id())->get('active')))
                                    ->value(1),
                                (new Label(__('Enable sessions on public pages'), Label::OUTSIDE_LABEL_AFTER))
                                    ->class('classic')
                                    ->for(My::id() . 'active'),
                            ]),
                        (new Para())
                            ->items([
                                (new Textarea(My::id() . 'connected', Html::escapeHTML((string) $blog_settings->get(My::id())->get('connected'))))
                                    ->rows(6)
                                    ->class('maximal')
                                    ->label((new Label(__('Text to display on login page when user is connected:'), Label::OL_TF))),
                            ]),
                        (new Para())
                            ->items([
                                (new Textarea(My::id() . 'disconnected', Html::escapeHTML((string) $blog_settings->get(My::id())->get('disconnected'))))
                                    ->rows(6)
                                    ->class('maximal')
                                    ->label((new Label(__('Text to display on login page when user is disconnected:'), Label::OL_TF))),
                            ]),
                    ])
                    ->render();
            },
            // blog settings update
            'adminBeforeBlogSettingsUpdate' => function (BlogSettingsInterface $blog_settings): void {
                $blog_settings->get(My::id())->put('active', !empty($_POST[My::id() . 'active']));
                $blog_settings->get(My::id())->put('connected', $_POST[My::id() . 'connected']);
                $blog_settings->get(My::id())->put('disconnected', $_POST[My::id() . 'disconnected']);
            },
            // simple menu type
            'adminSimpleMenuAddType' => function (ArrayObject $items) {
                if (My::settings()->get('active')) {
                    $items[My::id()] = new ArrayObject([__('Public login page'), false]);
                }
            },
            // simple menu select
            'adminSimpleMenuBeforeEdit' => function ($type, $select, &$attr) {
                if ($type == My::id()) {
                    $attr[0] = __('Login');
                    $attr[1] = __('Sign in to this blog');
                    $attr[2] = App::blog()->url() . App::url()->getURLFor(My::id());
                }
            },
        ]);

        return true;
    }
}

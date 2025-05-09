import 'package:flutter/material.dart';
import 'package:zaplab_design/zaplab_design.dart';
import 'section.dart';

class BaseTab extends StatelessWidget {
  const BaseTab({super.key});

  TabData tabData(BuildContext context) {
    // final theme = AppTheme.of(context);

    return TabData(
      label: 'Base',
      icon: const Icon(Icons.abc),
      content: Builder(
        builder: (context) {
          final theme = AppTheme.of(context);

          return AppContainer(
            padding: const AppEdgeInsets.all(AppGapSize.s16),
            child: Column(
              children: [
                Section(
                  title: 'AppSkeletonLoader',
                  description:
                      'This is a widget that fills the widget it is placed in with a gradient animation.',
                  children: [
                    AppContainer(
                      height: 144,
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                        color: theme.colors.grey66,
                        borderRadius: theme.radius.asBorderRadius().rad16,
                      ),
                      child: const AppSkeletonLoader(),
                    ),
                  ],
                ),
                Section(
                  title: 'AppCheckBox',
                  description: 'This is a classic checkbox widget.',
                  children: [
                    AppPanel(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              AppCheckBox(
                                value: false,
                                onChanged: (value) {},
                              ),
                              const AppGap(AppGapSize.s12),
                              AppText.reg14(
                                'Set to false (default)',
                                color: theme.colors.white66,
                              ),
                            ],
                          ),
                          const AppGap(AppGapSize.s16),
                          Row(
                            children: [
                              AppCheckBox(
                                value: true,
                                onChanged: (value) {},
                              ),
                              const AppGap(AppGapSize.s12),
                              AppText.reg14(
                                'Set to true',
                                color: theme.colors.white66,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Section(
                  title: 'AppSelector',
                  description:
                      'This simple selector widget can be used to select an option or to switch between the Tabs displayed under it. You can specify the mode of the selector by setting the emphasized parameter to true or false. The content of each AppSelectorButton can be separately defined for when it is selected and when it is not.',
                  children: [
                    AppContainer(
                      width: double.infinity,
                      child: AppText.h3(
                        'DEFAULT MODE',
                        color: theme.colors.white33,
                      ),
                    ),
                    const AppGap(AppGapSize.s12),
                    AppSelector(
                      children: [
                        AppSelectorButton(
                          selectedContent: const [AppText.med14('Option 1')],
                          unselectedContent: [
                            AppText.med14(
                              'Option 1',
                              color: theme.colors.white33,
                            )
                          ],
                          isSelected: true,
                          onTap: () {},
                        ),
                        AppSelectorButton(
                          selectedContent: [AppText.med14('Option 2')],
                          unselectedContent: [
                            AppText.med14(
                              'Option 2',
                              color: theme.colors.white33,
                            )
                          ],
                          isSelected: false,
                          onTap: () {},
                        ),
                        AppSelectorButton(
                          selectedContent: [AppText.med14('Option 3')],
                          unselectedContent: [
                            AppText.med14(
                              'Option 3',
                              color: theme.colors.white33,
                            )
                          ],
                          isSelected: false,
                          onTap: () {},
                        ),
                      ],
                      onChanged: (index) {},
                    ),
                    const AppGap(AppGapSize.s16),
                    AppContainer(
                      width: double.infinity,
                      child: AppText.h3(
                        'EMPHASIZED MODE',
                        color: theme.colors.white33,
                      ),
                    ),
                    const AppGap(AppGapSize.s12),
                    AppSelector(
                      emphasized: true,
                      children: [
                        AppSelectorButton(
                          selectedContent: [
                            AppIcon.s16(
                              theme.icons.characters.bell,
                              color: AppColorsData.dark().white,
                            ),
                            AppGap.s8(),
                            AppText.med14('21',
                                color: AppColorsData.dark().white),
                          ],
                          unselectedContent: [
                            AppIcon.s16(
                              theme.icons.characters.bell,
                              outlineColor: theme.colors.white33,
                              outlineThickness:
                                  LineThicknessData.normal().medium,
                            ),
                            AppGap.s8(),
                            AppText.med14('21', color: theme.colors.white33),
                          ],
                          isSelected: true,
                          onTap: () {},
                        ),
                        AppSelectorButton(
                          selectedContent: [
                            AppIcon.s16(
                              theme.icons.characters.reply,
                              outlineColor: AppColorsData.dark().white,
                              outlineThickness:
                                  LineThicknessData.normal().medium,
                            ),
                            AppGap.s8(),
                            AppText.med14(
                              '12',
                              color: AppColorsData.dark().white,
                            ),
                          ],
                          unselectedContent: [
                            AppIcon.s16(
                              theme.icons.characters.reply,
                              outlineColor: theme.colors.white33,
                              outlineThickness:
                                  LineThicknessData.normal().medium,
                            ),
                            AppGap.s8(),
                            AppText.med14('12', color: theme.colors.white33),
                          ],
                          isSelected: true,
                          onTap: () {},
                        ),
                        AppSelectorButton(
                          selectedContent: [
                            AppIcon.s18(
                              theme.icons.characters.zap,
                              color: AppColorsData.dark().white,
                            ),
                            AppGap.s8(),
                            AppText.med14('5',
                                color: AppColorsData.dark().white),
                          ],
                          unselectedContent: [
                            AppIcon.s18(
                              theme.icons.characters.zap,
                              outlineColor: theme.colors.white33,
                              outlineThickness:
                                  LineThicknessData.normal().medium,
                            ),
                            AppGap.s8(),
                            AppText.med14('5', color: theme.colors.white33),
                          ],
                          isSelected: true,
                          onTap: () {},
                        ),
                        AppSelectorButton(
                          selectedContent: [
                            AppIcon.s18(
                              theme.icons.characters.at,
                              outlineColor: AppColorsData.dark().white,
                              outlineThickness:
                                  LineThicknessData.normal().medium,
                            ),
                            AppGap.s8(),
                            AppText.med14('2',
                                color: AppColorsData.dark().white),
                          ],
                          unselectedContent: [
                            AppIcon.s18(
                              theme.icons.characters.at,
                              outlineColor: theme.colors.white33,
                              outlineThickness:
                                  LineThicknessData.normal().medium,
                            ),
                            AppGap.s8(),
                            AppText.med14('2', color: theme.colors.white33),
                          ],
                          isSelected: true,
                          onTap: () {},
                        ),
                        AppSelectorButton(
                          selectedContent: [
                            AppIcon.s18(
                              theme.icons.characters.emojiFill,
                              color: AppColorsData.dark().white,
                            ),
                            AppGap.s8(),
                            AppText.med14('2',
                                color: AppColorsData.dark().white),
                          ],
                          unselectedContent: [
                            AppIcon.s18(
                              theme.icons.characters.emojiLine,
                              outlineColor: theme.colors.white33,
                              outlineThickness:
                                  LineThicknessData.normal().medium,
                            ),
                            AppGap.s8(),
                            AppText.med14('2', color: theme.colors.white33),
                          ],
                          isSelected: true,
                          onTap: () {},
                        ),
                      ],
                      onChanged: (index) {},
                    ),
                  ],
                ),
                Section(
                  title: 'AppPanel',
                  description:
                      'This is an AppContainer with a predefined border radius, a default padding (that can be set to false) and a background color that auto-adjusts when used inside of an AppModal.',
                  children: [
                    AppPanel(
                      child: AppContainer(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: theme.colors.white8,
                          ),
                        ),
                        padding: const AppEdgeInsets.all(AppGapSize.s16),
                        child: Center(
                          child: AppText.reg14(
                            'Content',
                            color: theme.colors.white66,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // Section(
                //     title: 'AppScreen',
                //     description:
                //         'Screen that slides in from the bottom and lets you travel back to previous screens and the home screen in multiple ways.',
                //     children: [
                //       AppPanel(
                //         child: AppSmallButton(
                //           inactiveColor: theme.colors.white16,
                //           content: [
                //             AppText.med14('Open AppScreen',
                //                 color: theme.colors.white),
                //           ],
                //           onTap: () {
                //             AppScreen.show(
                //               context,
                //               topBarContent: AppText.med16(
                //                 'Current Screen',
                //               ),
                //               onHomeTap: () {
                //                 Navigator.of(context).pop();
                //               },
                //               history: [
                //                 HistoryItem(
                //                   contentType: 'Community',
                //                   title: 'Nips Out',
                //                 ),
                //                 HistoryItem(
                //                   contentType: 'Wiki',
                //                   title: 'NIP-B4 - History Links',
                //                 ),
                //                 HistoryItem(
                //                   contentType: 'Profile',
                //                   title: 'ثعبان',
                //                 ),
                //               ],
                //               child: Column(
                //                 children: [
                //                   AppPost(
                //                     profileName: 'ثعبان',
                //                     profilePicUrl:
                //                         'https://nostr.download/1aba957814cac9c324c54d94e0ba6606dc50af17f7c08654e9b9f139a9720d6d.jpeg',
                //                     timestamp: DateTime.now(),
                //                     content:
                //                         'I don\'t want to have to tap Back twelve times just to go back home 🏠. \n\nThat type of Big Tech UX is why hardly anyone ever wanders beyond like two clicks of tHe FeEd.',
                //                     communities: [
                //                       Community(
                //                         name: 'Nips Out',
                //                         profilePicUrl:
                //                             'https://cdn.satellite.earth/1895487e0fcd0db92babfa58501fd7cd319620c818e01d7bb941c4d465e4d685.png',
                //                       ),
                //                     ],
                //                   ),
                //                   AppTabView(
                //                     tabs: [
                //                       TabData(
                //                         label: 'Replies',
                //                         icon: AppIcon.s20(
                //                           theme.icons.characters.reply,
                //                           outlineColor: theme.colors.white66,
                //                           outlineThickness:
                //                               LineThicknessData.normal().medium,
                //                         ),
                //                         count: 21,
                //                         content: Column(
                //                           children: [
                //                             AppFeedPost(
                //                               content:
                //                                   'Yeah, this is why I\'m not using Nostr so much on mobile. The browser experience is king, for now.',
                //                               profileName: 'James Lewis',
                //                               profilePicUrl:
                //                                   'https://i.nostr.build/zdMAY.jpg',
                //                               timestamp: DateTime.now(),
                //                               zaps: [
                //                                 Zap(
                //                                   amount: 100,
                //                                   profileName: 'ثعبان',
                //                                   profilePicUrl:
                //                                       'https://nostr.download/1aba957814cac9c324c54d94e0ba6606dc50af17f7c08654e9b9f139a9720d6d.jpeg',
                //                                   timestamp: DateTime.now(),
                //                                 ),
                //                                 Zap(
                //                                   amount: 56,
                //                                   profileName: 'Pip',
                //                                   profilePicUrl:
                //                                       'https://m.primal.net/IfSZ.jpg',
                //                                   timestamp: DateTime.now(),
                //                                 ),
                //                               ],
                //                               reactions: [
                //                                 Reaction(
                //                                   emojiUrl:
                //                                       'https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Femojiguide.org%2Fimages%2Femoji%2Fc%2F1e2fb481tsfvyc.png&f=1&nofb=1&ipt=73d8789f7a055e207ff06bd2278184a2ab6108a8c019f59d0526d05f91d925e7&ipo=images',
                //                                   profilePicUrl:
                //                                       'https://nostr.download/1aba957814cac9c324c54d94e0ba6606dc50af17f7c08654e9b9f139a9720d6d.jpeg',
                //                                   profileName: "ثعبان",
                //                                   timestamp: DateTime.now(),
                //                                 ),
                //                                 Reaction(
                //                                   emojiUrl:
                //                                       'https://cdn.satellite.earth/60a5e73bfa6dfd35bd0b144f38f6ed2aaab0606b2bd68b623f419ae0709fa10a.png',
                //                                   profilePicUrl:
                //                                       'https://cdn.satellite.earth/946822b1ea72fd3710806c07420d6f7e7d4a7646b2002e6cc969bcf1feaa1009.png',
                //                                   profileName: "Niel Liesmons",
                //                                   timestamp: DateTime.now(),
                //                                 ),
                //                               ],
                //                               topReplies: [
                //                                 ReplyUserData(
                //                                   profileName: 'Vinney',
                //                                   profilePicUrl:
                //                                       'https://m.primal.net/HdAt.jpg',
                //                                 ),
                //                                 ReplyUserData(
                //                                   profileName: 'jrm',
                //                                   profilePicUrl:
                //                                       'https://pfp.nostr.build/e9e7963637e04d90ad2c33f21c6f112a188c5b001dd697e108991261487aa258.jpg',
                //                                 ),
                //                                 ReplyUserData(
                //                                   profileName: 'elsat',
                //                                   profilePicUrl:
                //                                       'https://image.nostr.build/ba781633731cd33bd20f58bbca208ae87db3f87c8f2256e23e4a8df543617c6c.png',
                //                                 ),
                //                               ],
                //                               totalReplies: 10,
                //                             ),
                //                             AppFeedPost(
                //                               content:
                //                                   'You might want to look into the AppScreen widget we have in the Zaplab Design package. It gives access to history links and home when the user swipes down on a screen.',
                //                               profileName: 'Niel Liesmons',
                //                               profilePicUrl:
                //                                   'https://cdn.satellite.earth/946822b1ea72fd3710806c07420d6f7e7d4a7646b2002e6cc969bcf1feaa1009.png',
                //                               timestamp: DateTime.now(),
                //                               zaps: [
                //                                 Zap(
                //                                   amount: 2100,
                //                                   profileName: 'Gzuuus',
                //                                   profilePicUrl:
                //                                       'https://pfp.nostr.build/3e72dab77cfcb2339a30a832c891064e38d70ad652cb58306516e34e78e84325.png',
                //                                   timestamp: DateTime.now(),
                //                                 ),
                //                               ],
                //                               topReplies: [
                //                                 ReplyUserData(
                //                                   profileName: 'jrm',
                //                                   profilePicUrl:
                //                                       'https://pfp.nostr.build/e9e7963637e04d90ad2c33f21c6f112a188c5b001dd697e108991261487aa258.jpg',
                //                                 ),
                //                                 ReplyUserData(
                //                                   profileName: 'elsat',
                //                                   profilePicUrl:
                //                                       'https://image.nostr.build/ba781633731cd33bd20f58bbca208ae87db3f87c8f2256e23e4a8df543617c6c.png',
                //                                 ),
                //                                 ReplyUserData(
                //                                   profileName: 'Pip',
                //                                   profilePicUrl:
                //                                       'https://m.primal.net/IfSZ.jpg',
                //                                 ),
                //                               ],
                //                               totalReplies: 6,
                //                             ),
                //                             AppFeedPost(
                //                               content: 'I feel you bro.',
                //                               profileName: 'elsat',
                //                               profilePicUrl:
                //                                   'https://image.nostr.build/ba781633731cd33bd20f58bbca208ae87db3f87c8f2256e23e4a8df543617c6c.png',
                //                               timestamp: DateTime.now(),
                //                             ),
                //                             AppFeedPost(
                //                               content:
                //                                   'True story, I rarely dive deep on mobile with the apps we have now.',
                //                               profileName: 'Pip',
                //                               profilePicUrl:
                //                                   'https://m.primal.net/IfSZ.jpg',
                //                               timestamp: DateTime.now(),
                //                             ),
                //                             AppFeedPost(
                //                               content: 'test test',
                //                               profileName: 'elsat',
                //                               profilePicUrl:
                //                                   'https://image.nostr.build/ba781633731cd33bd20f58bbca208ae87db3f87c8f2256e23e4a8df543617c6c.png',
                //                               timestamp: DateTime.now(),
                //                             ),
                //                             AppFeedPost(
                //                               content: 'test test',
                //                               profileName: 'elsat',
                //                               profilePicUrl:
                //                                   'https://image.nostr.build/ba781633731cd33bd20f58bbca208ae87db3f87c8f2256e23e4a8df543617c6c.png',
                //                               timestamp: DateTime.now(),
                //                             ),
                //                             AppFeedPost(
                //                               content: 'test test',
                //                               profileName: 'elsat',
                //                               profilePicUrl:
                //                                   'https://image.nostr.build/ba781633731cd33bd20f58bbca208ae87db3f87c8f2256e23e4a8df543617c6c.png',
                //                               timestamp: DateTime.now(),
                //                             ),
                //                             AppFeedPost(
                //                               content: 'test test',
                //                               profileName: 'elsat',
                //                               profilePicUrl:
                //                                   'https://image.nostr.build/ba781633731cd33bd20f58bbca208ae87db3f87c8f2256e23e4a8df543617c6c.png',
                //                               timestamp: DateTime.now(),
                //                             ),
                //                           ],
                //                         ),
                //                         settingsContent: AppContainer(
                //                           padding: const AppEdgeInsets.all(
                //                               AppGapSize.s64),
                //                           child: const AppText.reg14(
                //                               'Reply Settings Content'),
                //                         ),
                //                         settingsDescription:
                //                             'Choose which replies are displayed',
                //                       ),
                //                       TabData(
                //                         label: 'Shares',
                //                         icon: AppIcon.s20(
                //                           theme.icons.characters.share,
                //                           outlineColor: theme.colors.white66,
                //                           outlineThickness:
                //                               LineThicknessData.normal().medium,
                //                         ),
                //                         count: 5,
                //                         content: AppContainer(
                //                           padding: const AppEdgeInsets.all(
                //                               AppGapSize.s16),
                //                           child: Column(
                //                             children: List.generate(
                //                               5,
                //                               (index) => AppContainer(
                //                                 margin:
                //                                     const AppEdgeInsets.only(
                //                                         bottom: AppGapSize.s12),
                //                                 height: 60,
                //                                 child: Center(
                //                                   child: AppText.reg14(
                //                                       'Share ${index + 1}'),
                //                                 ),
                //                               ),
                //                             ),
                //                           ),
                //                         ),
                //                         settingsContent: AppContainer(
                //                           padding: const AppEdgeInsets.all(
                //                               AppGapSize.s16),
                //                           child: Column(
                //                             crossAxisAlignment:
                //                                 CrossAxisAlignment.start,
                //                             children: [
                //                               const AppText.med16(
                //                                   'Share Settings'),
                //                               const AppGap.s16(),
                //                               AppSwitch(
                //                                 value: AppResponsiveTheme.of(
                //                                             context)
                //                                         .colorMode ==
                //                                     AppThemeColorMode.grey,
                //                                 onChanged: (bool value) {
                //                                   Future.microtask(() {
                //                                     AppResponsiveTheme.of(
                //                                             context)
                //                                         .setColorMode(
                //                                       value
                //                                           ? AppThemeColorMode
                //                                               .grey
                //                                           : null,
                //                                     );
                //                                   });
                //                                 },
                //                               ),
                //                               const AppGap.s8(),
                //                               AppText.reg14(
                //                                 'Show share notifications',
                //                                 color: theme.colors.white66,
                //                               ),
                //                             ],
                //                           ),
                //                         ),
                //                         settingsDescription:
                //                             'Configure share notifications',
                //                       ),
                //                       TabData(
                //                         label: 'Lists',
                //                         icon: AppIcon.s20(
                //                           theme.icons.characters.label,
                //                           outlineColor: theme.colors.white66,
                //                           outlineThickness:
                //                               LineThicknessData.normal().medium,
                //                         ),
                //                         count: 103,
                //                         content: AppContainer(
                //                           padding: const AppEdgeInsets.all(
                //                               AppGapSize.s16),
                //                           child: Column(
                //                             children: List.generate(
                //                               103,
                //                               (index) => AppContainer(
                //                                 margin:
                //                                     const AppEdgeInsets.only(
                //                                         bottom: AppGapSize.s12),
                //                                 height: 60,
                //                                 child: Center(
                //                                   child: AppText.reg14(
                //                                       'List ${index + 1}'),
                //                                 ),
                //                               ),
                //                             ),
                //                           ),
                //                         ),
                //                         settingsContent: AppContainer(
                //                           padding: const AppEdgeInsets.all(
                //                               AppGapSize.s16),
                //                           child: Column(
                //                             crossAxisAlignment:
                //                                 CrossAxisAlignment.start,
                //                             children: [
                //                               const AppText.med16(
                //                                   'Like Settings'),
                //                               const AppGap.s16(),
                //                               const AppSwitch(),
                //                               const AppGap.s8(),
                //                               AppText.reg14(
                //                                 'Show like notifications',
                //                                 color: theme.colors.white66,
                //                               ),
                //                               const AppGap.s16(),
                //                               const AppSwitch(),
                //                               const AppGap.s8(),
                //                               AppText.reg14(
                //                                 'Group likes together',
                //                                 color: theme.colors.white66,
                //                               ),
                //                             ],
                //                           ),
                //                         ),
                //                         settingsDescription:
                //                             'Configure like notifications',
                //                       ),
                //                       TabData(
                //                         label: 'Tools',
                //                         icon: AppIcon.s20(
                //                           theme.icons.characters.tools,
                //                           outlineColor: theme.colors.white66,
                //                           outlineThickness:
                //                               LineThicknessData.normal().medium,
                //                         ),
                //                         content: AppContainer(
                //                           padding: const AppEdgeInsets.all(
                //                               AppGapSize.s16),
                //                           child: AppText.reg14(
                //                               'Display Tools in a Grid'),
                //                         ),
                //                       ),
                //                       TabData(
                //                         label: 'Details',
                //                         icon: AppIcon.s20(
                //                           theme.icons.characters.details,
                //                           outlineColor: theme.colors.white66,
                //                           outlineThickness:
                //                               LineThicknessData.normal().medium,
                //                         ),
                //                         content: AppContainer(
                //                           padding: const AppEdgeInsets.all(
                //                               AppGapSize.s16),
                //                           child:
                //                               AppText.reg14('Details Content'),
                //                         ),
                //                       ),
                //                     ],
                //                   ),
                //                 ],
                //               ),
                //             );
                //           },
                //         ),
                //       ),
                //     ]),
                Section(
                  title: 'AppSwitch',
                  description:
                      'This is a switch widget that can be used to toggle between two states.',
                  children: [
                    AppPanel(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppText.med14(
                            'Grey Mode',
                            color: theme.colors.white,
                          ),
                          AppSwitch(
                            value: AppResponsiveTheme.of(context).colorMode ==
                                AppThemeColorMode.grey,
                            onChanged: (bool value) {
                              Future.microtask(() {
                                AppResponsiveTheme.of(context).setColorMode(
                                  value ? AppThemeColorMode.grey : null,
                                );
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Section(
                    title: 'AppCodeBlock',
                    description:
                        'This is a code block widget that can be used to display code in a readable format.',
                    children: [
                      const AppCodeBlock(
                        code: r'''{     
  kind: 7375,     
  content: "Thanks for the coffee",
  pubkey: "sender-pubkey",    
  tags: [         
     [ "amount", "1000", "msat" ],        
     [ "token", "cashuAeyJ0b2tlbiI6W3sicHJvb2ZzIjpbeyJpZCI6IjAwNDE0NmJkZjRhOWFmYWIiLCJhbW91bnQiOjEsInNlY3JldCI6IltcIlAyUEtcIix7XCJub25jZVwiOlwiYjI0NDNkZDRmMDQxNjgyYjRkMmEwMzkwNGQ5MDAyNjRiNzI1MzgwZTQ0YWM0MDk2Y2EwZWE2NDAzMGY0Mjc4OFwiLFwiZGF0YVwiOlwiZTlmYmNlZDNhNDJkY2Y1NTE0ODY2NTBjYzc1MmFiMzU0MzQ3ZGQ0MTNiMzA3NDg0ZTRmZDE4MThhYjUzZjk5MTExXCJ9XSIsIkMiOiIwMjYyOTM5ODRjODg1OTFiMzA2MzUxYjY5ZmNjODAxNGQ1NTc5MmYzMTQwYWEyZDlhYmQ0NGZhOWY0Y2Y2ZmQzZjEifV0sIm1pbnQiOiJodHRwczovL3N0YWJsZW51dC51bWludC5jYXNoIn1dLCJ1bml0Ijoic2F0In0="]         
     [ "u", "https://stablenut.umint.cash", ],
     [ "e", "<zapped-event-id>" ],
     [ "p", "e9fbced3a42dcf551486650cc752ab354347dd413b307484e4fd1818ab53f991" ]
  ] 
}''',
                        language: 'JSON',
                      ),
                    ]),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => tabData(context).content;
}

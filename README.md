TAPevents Internationalization (tap-i18n)
=========================================

A comprehensive internationalization solution for Meteor.

tap-i18n encapsulates the [i18next](http://i18next.com/) JavaScript library to
make its capabilities available for Meteor packages developers.

Though the decision to translate a package and to internationalize it is a
decision made by the **package** developer, the control over the
internationalization configurations are done by the **project** developer and
are global to all the packages in a certain project.

Therefore if you'll wish to use this package to internationalize your Meteor
package your docs will have to refer project developers that will use it to
the "Usage - Project Developers" section below to enable internationalization.
If the project developer won't enable tap-i18n your package will be served in
a default language of your choice.

Once tap-i18n is enabled on the project level we automatically pack the
languages files of all the packages the project uses, one file per language.
These files will be loaded dynamically only when they are needed by the client.
tap-i18n gives the project developer the flexibility to choose how these files
will be delivered to the clients (Meteor internal files server, nginx, cdn,
etc.) according to needs and constraints.

The unified languages files generated for tap-i18n enabled projects are built
seamlessly upon change (as part of Meteor build) without the need to run any
external scripts.

Languages Tags and Translations Prioritization
----------------------------------------------

We use the [IETF language tag system](http://en.wikipedia.org/wiki/IETF_language_tag)
for languages tagging. With it developers can refer to a certain language in
general or pick one of it's dialects.

Example: A developer can either refer to English in general using: "en" or to the
Great Britain dialect with "en-GB".

Notes:
* "en-US" is the dialect we use for the base English translations "en".
* We currently support only one dialect level. e.g. nan-Hant-TW is not supported.

If tap-i18n is enabled in the project level we'll attempt to look for a
translation of certain string in the following order:

* Language dialect, if specified ("pt-BR")
* Base language ("pt")
* Base English ("en")

If tap-i18n is not enabled in the project level the language set by packages
developers as their default languages will be used.

Usage - Package Developers
--------------------------

### Setup tap-i18n

In order to use tap-i18n to internationalize your package:

**Step 1:** Add the package-tap.i18n configuration file to your **package root**:

The values below are the defaults, you can use empty JSON object if you don't
need to change them.

    package_dir/package-tap.i18n
    ----------------------------
    {
        languages_files_dir: "i18n", // the path to your languages files
                                     // directory relative to your package root
        default_language: "en" // if the project won't enable tap-i18n in the
                               // project level the package will be served in
                               // the default_language
    }

**Important:** You must set this file in your package root.

**Step 2:** Create your languages\_files\_dir:

Example for the default languages\_files\_dir path and its structure:

    .
    |--package_name
    |----package.js
    |----package-tap.i18n
    |----i18n # Should be the same path as languages_files_dir option above
    |------en.i18n.json
    |------fr.i18n.json
    |------pt.i18n.json
    |------pt-BR.i18n.json
    .
    .
    .

**Step 3:** Setup your package.js:

Your package's package.js should be structured as follow:

    Package.on_use(function (api) {
      api.use(['tap-i18n'], ['client']);
    
      .
      .
      .
    
      // You must load your package's package-tap.i18n before you load any
      // template
      api.add_files("package-tap.i18n", ['client']);
    
      // Templates loads (if any)
    
      // List your languages files so Meteor will watch them and rebuild your
      // package as they change
      // You must load the languages files after you loaded your templates -
      // otherwise the templates won't have the i18n capabilities (unless you'll
      // register them with tap-i18n yourself, see below)
      api.add_files([
        "i18n/en.i18n.json",
        "i18n/fr.i18n.json",
        "i18n/pt.i18n.json",
        "i18n/pt-br.i18n.json",
      ], ['client']);
    });

Note: The fact that all the languages files are added in the package.js doesn't
mean that they will all actually be loaded for every single client that uses
your package. We use this listing for two purposes: (1) to be able to watch
these files for changes to trigger rebuild, and (2) to have a mark in the
package loading process in which we know all the templates of the package
are loaded so we can register them with tap-i18n.

### Structure of Languages Files

Languages files must be named by their language tag name with the i18n.json
suffix.

Example for languages files:

    en.i18n.json
    {
        "sky": "Sky",
        "color": "Color"
    }

    pt.i18n.json
    {
        "sky": "Céu",
        "color": "Cor"
    }

    fr.i18n.json
    {
        "sky": "Ciel"
    }

    en-GB.i18n.json
    {
        "color": "Colour"
    }

Notes:

* To avoid translation bugs all the keys in your package must be translated to
  English ("en") which is the fallback language when projects enable tap-i18n
  and to your project's default language (set in your package-tap.i18n) for case your
  package will be used by projects that don't enable tap-i18n.
* Remember that thanks to the Languages Tags and Translations Prioritization
  (see above) if a translation for a certain string is the same for a language
  and its dialect you don't need to translate it again in the dialect file.
  See that in the example above there is no need to translate "sky" in en-GB
  which is the same in en.
* The French file above have no translation for the color key above, it will
  fallback to English.
* Check [i18next features documentation](http://i18next.com/pages/doc_features.html) for
  more advanced translations structures you can use in your JSONs files (Such as
  variables, plural form, etc.).

### tap-i18n Functions:

The following functions are added to your package namespace by tap-i18n:

**\_\_("key", options) (Client)**

Translates key to the current client's language. If inside a reactive
computation, invalidate the computation the next time the client language get
changed (by TapI18n.setLanguage).

The function is a proxy to i18next.t() method. 
Refer to the [documentation of i18next.t()](http://i18next.com/pages/doc_features.html)
to learn about its possible options.

**registerTemplate(template\_name) (Client)**

This function defines the \_ helper that maps to the \_\_ function for the
template with the given name.

**Important:** tap-i18n registers the templates defined by your package prior to
startup automatically. You have to register only templates that you define
dynamically after Meteor loads.

### Handlebars Helper:

tap-i18n registered templates will have the _ handlebars helper:

    {{_ "key" "sprintf_arg1" "sprintf_arg2" ... op1="option-value" op2="option-value" ... }}

**Examples:**

Assuming the client language is en.

**Example 1:** Simple key:

    en.i18n.json:
    -------------
    {
        "click": "Click Here"
    }

    page.html:
    ----------
    <template "x">
        {{_ "click"}}
    </template>

    output:
    -------
    Click Here

**Example 2:** Sprintf:

    en.i18n.json:
    -------------
    {
        "hello": "Hello %s, your last visit was on: %s"
    }

    page.html:
    ----------
    <template "x">
        {{_ "hello" "Daniel" "2014-05-22"}}
    </template>

    output:
    -------
    Hello Daniel, your last visit was on: 2014-05-22

**Example 3:** Named variables and sprintf:

    en.i18n.json:
    -------------
    {
        "hello": "Hello __user_name__, your last visit was on: %s"
    }

    page.html:
    ----------
    <template "x">
        {{_ "hello" "2014-05-22" user_name="Daniel"}}
    </template>

    output:
    -------
    Hello Daniel, your last visit was on: 2014-05-22

**Note:** Named variables have to be after all the sprintf parameters.

**Example 4:** Named variables, sprintf, singular/plural:

    en.i18n.json:
    -------------
    {
        "inbox_status": "__username__, You have a new message (inbox last checked %s)",
        "inbox_status_plural": "__username__, You have __count__ new messages (last checked %s)"
    }

    page.html:
    ----------
    <template "x">
        {{_ "inbox_status" "2014-05-22" username="Daniel" count=1}}
        {{_ "inbox_status" "2014-05-22" username="Chris" count=4}}
    </template>

    output:
    -------
    Daniel, You have a new message (inbox last checked 2014-05-22)
    Chris, You have 4 new messages (last checked 2014-05-22)

**Example 5:** Singular/plural, context:

    en.i18n.json:
    -------------
    {
        "actors_count": "There is one actor in the movie",
        "actors_count_male": "There is one actor in the movie",
        "actors_count_female": "There is one actress in the movie",
        "actors_count_plural": "There are __count__ actors in the movie",
        "actors_count_male_plural": "There are __count__ actors in the movie",
        "actors_count_female_plural": "There are __count__ actresses in the movie",
    }

    page.html:
    ----------
    <template "x">
        {{_ "actors_count" count=1 }}
        {{_ "actors_count" count=1 context="male" }}
        {{_ "actors_count" count=1 context="female" }}
        {{_ "actors_count" count=2 }}
        {{_ "actors_count" count=2 context="male" }}
        {{_ "actors_count" count=2 context="female" }}
    </template>

    output:
    -------
    There is one actor in the movie
    There is one actor in the movie
    There is one actress in the movie
    There are 2 actors in the movie
    There are 2 actors in the movie
    There are 2 actresses in the movie

Notes:

* The translation will get updated automatically after you change the language
  with TapI18n.setLanguage().
* Refer to the [documentation of i18next.t()](http://i18next.com/pages/doc_features.html)
  to learn more about its possible options.

Usage - Project Developers
--------------------------

Once you'll enable tap-i18n in your project you'll be able to set the
translation language for each client during run-time.

### Enabling tap-i18n

**Step 1:** Add the tap-i18n package:

    $ mrt add tap-i18n

**Step 2:** Add the **project-tap.i18n** configuration file to your **project root**:

The values below are the defaults, you can use empty JSON object if you don't
need to change them.

    project-root/project-tap.i18n
    -----------------------------
    {
        supported_languages: ["en"],
        build_files_path: "public/i18n", // can be a relative to project root or absolute
        browser_path: "/i18n" // can be a full url, or an absolute path on the project domain
    }

Notes: 
* We use AJAX to load the languages files so if your browser\_path is in
  another domain you'll have to set CORS on it.
* The supported\_languages array specify the languages the project users can
  pick from. If you specify a dialect as one of the supported languages its
  base language will be supported also. Since English is used by tap-i18n as the
  fallback language it is always supported, even if it isn't listed in the array.

**Step 3:** Set a language on the client startup:

    if (Meteor.isClient) {
      Meteor.startup(function () {
        Session.set("showLoadingIndicator", true);
    
        TapI18n.setLanguage(getUserLanguage())
          .done(function () {
            Session.set("showLoadingIndicator", false);
          })
          .fail(function (error_message) {
            // Handle the situation
            console.log(error_message);
          });
      });
    }

Notes:
* Read TapI18n.setLanguage documentation in the API section below.
* If you won't set a language on startup your project will be served by the
  fallback language: English.
* You probably want to show a loading indicator until the language is ready (as
  shown in the example), otherwise the templates in your projects will be in
  the fallback language English until the language will be ready.

### Disabling tap-i18n:

1. Remove **project-tap.i18n**.
2. Remove the unified languages files that were built to your project's build\_files\_path.

### TapI18n API:

**TapI18n.setLanguage(language\_tag) (Client)**

Sets the client's translation language.

Returns a jQuery deferred object that resolves if the language load
succeed and fails otherwise.

Notes:
  * Expect it to fail if tap-i18n is not enabled in the project level.
  * See usage example in the (Usage - Project Developers) Enabling tap-i18n
    section above.
  * jQuery deferred docs: [jQuery Deferred](http://api.jquery.com/jQuery.Deferred/)
  * language\_tag has to be a supported language.

**TapI18n.getLanguage() (Client)**

Returns the language tag of the client's translation language or null if
tap-i18n is not enabled in the project level.

If inside a reactive computation, invalidate the computation the next time the
client language get changed (by TapI18n.setLanguage)

Unit Testing
------------

In order to run the package unit-tests run:

    $ ./unit-test.bash

When testing the build system it is useful to be able to restart the unittest
fast, with the following you can ctrl-c to restart:

    $ while : ; do ./unit-test.bash disabled; sleep 1; done

Credits
-------

**Libraries:**

* [i18next](http://i18next.com/)
* [wrench-js](https://github.com/ryanmcgrath/wrench-js)


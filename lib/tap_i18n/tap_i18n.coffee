# Put TapI18n in the global namespace
TapI18n = {}

fallback_language = "en"

sessions_prefix = "TapI18n::"
loaded_lang_session_key = "#{sessions_prefix}loaded_lang"
# Before the first language is ready - loaded_lang is null
Session.set loaded_lang_session_key, null

_.extend TapI18n,
  conf: null # This parameter will be set by the js that is being added by the
             # build plugin of project-tap.i18n (which exist only if tap-i18n
             # is enabled in the project level)
             # if it isn't null we assume that it is valid (we clean and
             # validate it throughly during the build process)

  _enabled: ->
    # read the comment of @conf
    @conf?

  _loaded_languages: []
  _loadLanguage: (languageTag) ->
    # Load languageTag and its dependencies languages to TapI18next if we
    # haven't loaded them already.
    #
    # languageTag dependencies languages are:
    # * The base language if languageTag is a dialect.
    # * The fallback language (en) if we haven't loaded it already.
    #
    # Returns a deferred object that resolves with no arguments if all files
    # loaded successfully to TapI18next and rejects with array of error
    # messages otherwise
    #
    # Example:
    # TapI18n._loadLanguage("pt-BR")
    #   .done(function () {
    #     console.log("languageLoaded successfully");
    #   })
    #   .fail(function (messages) {
    #     console.log("Couldn't load languageTag", messages);
    #   })
    #
    # The above example will attempt to load pt-BR, pt and en

    dfd = new $.Deferred()

    if not @_enabled()
      return dfd.reject "tap-i18n is not enabled in the project level, check tap-i18n README"

    self = @

    if (languageTag in self.conf.supported_languages)
      if not (languageTag in self._loaded_languages)
        loadLanguageTag = ->
          jqXHR = $.getJSON("#{self.conf.browser_path}/#{languageTag}.tap-i18n.json")

          jqXHR.done (data) ->
            for package_name, package_keys of data
              TapI18next.addResourceBundle(languageTag, package_name, package_keys)

            self._loaded_languages.push languageTag

            dfd.resolve()

          jqXHR.fail (xhr, error_code) ->
            dfd.reject("Couldn't load language '#{languageTag}' JSON: #{error_code}")

        if languageTag != fallback_language
          # Since languageTag is in self.conf.supported_languages and self.conf is
          # carefully validated during the build process we can count on
          # languageTag to be a valid language tag
          directDependencyLanguageTag = if "-" in languageTag then languageTag.replace(/-.*/, "") else fallback_language

          dependencyLoadDfd = self._loadLanguage directDependencyLanguageTag

          dependencyLoadDfd.done ->
            # All dependencies loaded successfully
            loadLanguageTag()

          dependencyLoadDfd.fail (message) ->
            dfd.reject("Loading process failed since dependency language
              '#{directDependencyLanguageTag}' failed to load: " + message)
        else
          loadLanguageTag()
      else
        # languageTag loaded already
        dfd.resolve()
    else
      dfd.reject(["Language #{languageTag} is not supported"])

    return dfd

  _registerTemplateHelper: (package_name, template) ->
    tapI18nextProxy = @_getPackageI18nextProxy(package_name)

    Template[template]._ = (key, args...) ->
      options = (args.pop()).hash
      if not _.isEmpty(args)
        options.sprintf = args

      tapI18nextProxy(key, options)

  _getPackageRegisterTemplateHelperProxy: (package_name) ->
    # A proxy to _registerTemplateHelper where the package_name is fixed to package_name
    self = @
    (template) ->
      self._registerTemplateHelper(package_name, template)

  _getPackageI18nextProxy: (package_name) ->
    # A proxy to TapI18next.t where the namespace is preset to the package's
    (key, options) ->
      # If inside a reactive computation, we want to invalidate the computation if the client lang changes
      Session.get loaded_lang_session_key

      TapI18next.t "#{package_name}:#{key}", options

  setLanguage: (lang_tag) ->
    @_loadLanguage(lang_tag).then ->
      TapI18next.setLng(lang_tag)

      Session.set loaded_lang_session_key, lang_tag

  getLanguage: ->
    Session.get loaded_lang_session_key

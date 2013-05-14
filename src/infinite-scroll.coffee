mod = angular.module('infinite-scroll', [])

mod.directive 'infiniteScroll', ['$rootScope', '$window', '$timeout', ($rootScope, $window, $timeout) ->
  link: (scope, elem, attrs) ->
    $window = angular.element($window)

    # infinite-scroll-distance specifies how close to the bottom of the page
    # the window is allowed to be before we trigger a new scroll. The value
    # provided is multiplied by the window height; for example, to load
    # more when the bottom of the page is less than 3 window heights away,
    # specify a value of 3. Defaults to 0.
    scrollDistance = 0
    if attrs.infiniteScrollDistance?
      scope.$watch attrs.infiniteScrollDistance, (value) ->
        scrollDistance = parseInt(value, 10)

    # infinite-scroll-disabled specifies a boolean that will keep the
    # infnite scroll function from being called; this is useful for
    # debouncing or throttling the function call. If an infinite
    # scroll is triggered but this value evaluates to true, then
    # once it switches back to false the infinite scroll function
    # will be triggered again.
    scrollEnabled = true
    checkWhenEnabled = false
    if attrs.infiniteScrollDisabled?
      scope.$watch attrs.infiniteScrollDisabled, (value) ->
        scrollEnabled = !value
        if scrollEnabled && checkWhenEnabled
          checkWhenEnabled = false
          handler()

    container = $window

    # infinite-scroll-container sets the container which we want to be
    # infinte scrolled, instead of the whole window window. Must be an
    # Angular or jQuery element.
    if attrs.infiniteScrollContainer?
      scope.$watch attrs.infiniteScrollContainer, (value) ->
        value = angular.element(value)
        if value?
          container = value
        else
          throw new Exception("invalid infinite-scroll-container attribute.")

    # infinite-scroll-parent establishes this element's parent as the
    # container infinitely scrolled instead of the whole window.
    if attrs.infiniteScrollParent?
      container = elem.parent()
      scope.$watch attrs.infiniteScrollParent, () ->
        container = elem.parent()

    # infinite-scroll specifies a function to call when the window,
    # or some other container specified by infinite-scroll-container,
    # is scrolled within a certain range from the bottom of the
    # document. It is recommended to use infinite-scroll-disabled
    # with a boolean that is set to true when the function is
    # called in order to throttle the function call.
    handler = ->
      if container == $window
        containerBottom = container.height() + container.scrollTop()
        elementBottom = elem.offset().top + elem.height()
      else
        containerBottom = container.height()
        elementBottom = elem.offset().top - container.offset().top + elem.height()
      remaining = elementBottom - containerBottom
      shouldScroll = remaining <= container.height() * scrollDistance

      if shouldScroll && scrollEnabled
        if $rootScope.$$phase
          scope.$eval attrs.infiniteScroll
        else
          scope.$apply attrs.infiniteScroll
      else if shouldScroll
        checkWhenEnabled = true

    container.on 'scroll', handler
    scope.$on '$destroy', ->
      container.off 'scroll', handler

    $timeout (->
      if attrs.infiniteScrollImmediateCheck
        if scope.$eval(attrs.infiniteScrollImmediateCheck)
          handler()
      else
        handler()
    ), 0
]

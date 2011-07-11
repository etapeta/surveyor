module Surveyor
  class NoBaseValueError < ::StandardError; end
  class ValidSurveyError < ::StandardError; end
  class InvalidFieldMatchError < ::StandardError; end
  class UnknownFieldError < ::StandardError; end
  class SmallerArrayError < ::StandardError; end
  class ImplementedBySubclassError < ::StandardError; end
  class TooMuchContentError < ::StandardError; end
  class WrongParentError < ::StandardError; end
  class CannotMultiplyError < ::StandardError; end
end

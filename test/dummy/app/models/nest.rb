class Nest < ActiveRecord::Base
  serialize :document, Hash

end

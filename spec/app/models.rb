# Load order matters: parents before subclasses, readers in the expected registration order
require 'app/models/reader'
require 'app/models/different_reader'
require 'app/models/customer'
require 'app/models/sti_reader'
require 'app/models/document'
require 'app/models/email'
require 'app/models/multi_level_sti_readable'

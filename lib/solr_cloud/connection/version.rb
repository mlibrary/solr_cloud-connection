# frozen_string_literal: true

require "delegate" # needed so ruby doesn't complain about mismatched declarations

module SolrCloud
  class Connection < SimpleDelegator
    VERSION = "0.1.0"
  end
end

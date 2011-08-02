require "yajl"
class ApplicationController < ActionController::Base
  protect_from_forgery

  def encode_to_json(data)
    Yajl::Encoder.encode(data)
  end
end

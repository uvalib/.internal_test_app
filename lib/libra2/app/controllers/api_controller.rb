require_dependency 'libra2/lib/serviceclient/auth_token_client'

class APIController < ApplicationController

  # disable rails auth behavior and add our own
  skip_before_filter :require_auth
  skip_before_filter :verify_authenticity_token
  before_action :validate_token
  before_action :validate_user, only: [ :delete, :update_title ]

  #
  # define the response structures
  #

  # the work query response
  class WorksResponse

    attr_accessor :status
    attr_accessor :works

    def initialize( status, works )
      @status = status
      @works = works
    end
  end

  # the command response
  class CommandResponse

    attr_accessor :status

    def initialize( status )
      @status = status
    end
  end

  #
  # /api/v1/all
  #
  def all
    works = GenericWork.all
    if works.empty?
       status = 404
       render json: WorksResponse.new( status, [] ), :status => status
    else
       status = 200
       render json: WorksResponse.new( status, works ), :status => status
    end

  end

  #
  # /api/v1/:id
  #
  def get
    work = get_the_work
    if work.nil?
      status = 404
      render json: WorksResponse.new( status, [] ), :status => status
    else
      status = 200
      render json: WorksResponse.new( status, [ work ] ), :status => status
    end

  end

  #
  # /api/v1/:id
  #
  def delete
    work = get_the_work
    if work.nil?
      status = 404
      render json: CommandResponse.new( status ), :status => status
    else
      # actually do the delete
      status = 200
      render json: CommandResponse.new( status ), :status => status
    end
  end

  #
  # /api/v1/:id/title/:title
  #
  def update_title
    work = get_the_work
    if work.nil?
      status = 404
      render json: CommandResponse.new( status ), :status => status
    else
      # actually update the title
      status = 200
      render json: CommandResponse.new( status ), :status => status
    end
  end

  private

  def get_the_work
    id = params[:id]
    begin
      return GenericWork.find( id )
    rescue => e
    end
    return nil
  end

  def validate_token
    auth = params[:auth]
    if valid_auth( auth )
      return
    end
    status = 401
    render json: CommandResponse.new( status ), :status => status
  end

  def valid_auth( auth )
    status = ServiceClient::AuthTokenClient.instance.auth( 'api', 'access', auth )
    return ServiceClient::AuthTokenClient.instance.ok?( status )
  end

  def validate_user
    user = params[:user]
  end

end

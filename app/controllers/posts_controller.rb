class PostsController < ApplicationController
  def index
    @posts = js_bind(Post.all, :posts, url: posts_url)
  end

  ## All routes except index are JSON only
  def show
    @post = Post.find(params[:id])
  end

  # accepts mass create/update as well as individual create
  def update
    if post_params
      @post = do_update(post_params) # do individual update

      respond_to do |format|
        if @post.save
          format.json { render :show, status: :ok }
        else
          format.json { render json: @post.errors, status: :unprocessable_entity }
        end
      end

    else
      mass_create_update
    end
  end

  # accepts mass create/update as well as individual create
  def create
    if post_params
      @post = do_create(post_params) # do individual create

      if @post.save
        render :show, status: :created
      else
        render json: @post.errors, status: :unprocessable_entity
      end

    else
      mass_create_update
    end
  end

  private

  def mass_create_update
    @posts = posts_params.map do |params|
      if ( params[:id] )
        do_update(params)
      else
        do_create(params)
      end
    end

    # make sure all are valid before save
    if @posts.reduce {|memo, post| memo && post.valid? }
      @posts.each {|post| post.save }
      render :index
    else
      render json: ( @posts.map {|post| post.errors} ), status: :unprocessable_entity
    end
  end

  def do_create(params)
    Post.new(post_params)
  end

  def do_update(params)
    post = Post.find(params[:id])
    post.attributes = params
    return post
  end

  def posts_params
    params.permit(posts: [:id, :title, :body])[:posts] # multiple records
  end

  def post_params
    params.require(:post).permit(:id, :title, :body) rescue nil # single record
  end

end

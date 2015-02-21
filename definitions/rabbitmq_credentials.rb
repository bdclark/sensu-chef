define :rabbitmq_credentials do
  rabbitmq_vhost params[:vhost] do
    action :add
  end

  rabbitmq_user "add #{params[:user]}" do
    user params[:user]
    password params[:password]
    action :add
  end

  rabbitmq_user "set_permissions #{params[:user]}" do
    user params[:user]
    vhost params[:vhost]
    permissions params[:permissions] || ".* .* .*"
    action :set_permissions
  end
end

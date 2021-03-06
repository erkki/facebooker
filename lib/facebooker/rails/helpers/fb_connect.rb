module Facebooker
  module Rails
    module Helpers
      module FbConnect
        
        def fb_connect_javascript_tag
          if request.ssl?
            javascript_include_tag "https://www.connect.facebook.com/js/api_lib/v0.4/FeatureLoader.js.php"
          else
            javascript_include_tag "http://static.ak.connect.facebook.com/js/api_lib/v0.4/FeatureLoader.js.php"
          end
        end
        
        def init_fb_connect(*required_features,&proc)
          additions = ""
          if block_given?
            additions = capture(&proc)
          end

          options = {:js => :prototype}
          if required_features.last.is_a?(Hash)
            options.merge!(required_features.pop.symbolize_keys)
          end

          if request.ssl?
            init_string = "FB.Facebook.init('#{Facebooker.api_key}','/xd_receiver_ssl.html');"
          else
            init_string = "FB.Facebook.init('#{Facebooker.api_key}','/xd_receiver.html');"
          end
          unless required_features.blank?
             init_string = <<-FBML
             #{case options[:js]
               when :jquery then "$(document).ready("
               else "Element.observe(window,'load',"
               end} function() {
                FB_RequireFeatures(#{required_features.to_json}, function() {
                  #{init_string}
                  #{additions}
                });
              });
              FBML
          end

          # block_is_within_action_view? is rails 2.1.x and has been
          # deprecated.  rails >= 2.2.x uses block_called_from_erb?
          block_tester = respond_to?(:block_is_within_action_view?) ?
            :block_is_within_action_view? : :block_called_from_erb?

          if block_given? && send(block_tester, proc)
            concat(javascript_tag(init_string))
          else
            javascript_tag init_string
          end
        end
  
        # Render an <fb:login-button> element
        # 
        # ==== Examples
        #
        # <%= fb_login_button%>
        # => <fb:login-button></fb:login-button>
        #
        # Specifying a javascript callback
        #
        # <%= fb_login_button 'update_something();'%>
        # => <fb:login-button onlogin='update_something();'></fb:login-button>
        #
        # Adding options <em>See:</em> http://wiki.developers.facebook.com/index.php/Fb:login-button
        #
        # <%= fb_login_button 'update_something();', :size => :small, :background => :dark%>
        # => <fb:login-button background='dark' onlogin='update_something();' size='small'></fb:login-button>
        #
        def fb_login_button(*args)

          callback = args.first
          options = args[1] || {}
          options.merge!(:onlogin=>callback)if callback

          content_tag("fb:login-button",nil, options)
        end

        def fb_login_and_redirect(url, options = {})
          js = update_page do |page|
            page.redirect_to url
          end
          content_tag("fb:login-button",nil,options.merge(:onlogin=>js))
        end
        
        def fb_unconnected_friends_count
          content_tag "fb:unconnected-friends-count",nil
        end
        
        def fb_logout_link(text,url,*args)
          js = update_page do |page|
            page.call "FB.Connect.logoutAndRedirect",url
          end
          link_to_function text, js, *args
        end
        
        def fb_user_action(action, user_message = "", prompt = "", callback = nil)
          update_page do |page|
            page.call "FB.Connect.showFeedDialog",action.template_id,action.data,action.target_ids,action.body_general,nil,page.literal("FB.RequireConnect.promptConnect"),callback,prompt,user_message
          end
        end
        
      end
    end
  end
end

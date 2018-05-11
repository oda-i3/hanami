module Hanami
  class CLI
    module Commands
      module Destroy
        # @since 1.1.0
        # @api private
        class App < Command
          desc "Destroy an app"

          argument :app, required: true, desc: "The application name (eg. `web`)"

          example [
            "admin # Destroy `admin` app"
          ]

          # @since 1.1.0
          # @api private
          def call(app:, **options) # rubocop:disable Metrics/MethodLength
            app     = Utils::String.underscore(app)
            context = Context.new(app: app, options: options)

            assert_valid_app!(context)
            context = context.with(base_url: base_url(context))

            remove_test_http_session_secret(context)
            remove_development_http_session_secret(context)

            remove_mount_app(context)
            remove_require_app(context)

            recursively_destroy_precompiled_assets(context)
            destroy_assets_manifest(context)

            recursively_destroy_specs(context)
            recursively_destroy_app(context)
          end

          private

          # @since 1.1.0
          # @api private
          def assert_valid_app!(context)
            return if project.app?(context)

            existing_apps = project.apps.map { |name| "`#{name}'" }.join(' ')
            warn "`#{context.app}' is not a valid APP. Please specify one of: #{existing_apps}"
            exit(1)
          end

          # @since 1.1.0
          # @api private
          def remove_test_http_session_secret(context)
            content = "#{context.app.upcase}_SESSIONS_SECRET"
            path    = project.env(context, "test")

            generator.remove_line(path, content)
          end

          # @since 1.1.0
          # @api private
          def remove_development_http_session_secret(context)
            content = "#{context.app.upcase}_SESSIONS_SECRET"
            path    = project.env(context, "development")

            generator.remove_line(path, content)
          end

          # @since 1.1.0
          # @api private
          def remove_mount_app(context)
            content = "mount #{context.app.classify}::Application"
            path    = project.environment(context)

            generator.remove_line(path, content)
          end

          # @since 1.1.0
          # @api private
          def remove_require_app(context)
            content = "require_relative '../apps/#{context.app}/application'"
            path    = project.environment(context)

            generator.remove_line(path, content)
          end

          # @since 1.1.0
          # @api private
          def recursively_destroy_precompiled_assets(context)
            destination = project.public_app_assets(context)
            return unless files.directory?(destination)

            generator.delete_directory(destination)
          end

          # @since 1.1.0
          # @api private
          def destroy_assets_manifest(context)
            path = project.assets_manifest(context)

            generator.delete(path, allow_missing: true)
          end

          # @since 1.1.0
          # @api private
          def recursively_destroy_specs(context)
            path = project.app_spec(context)

            generator.delete_directory(path)
          end

          # @since 1.1.0
          # @api private
          def recursively_destroy_app(context)
            path = project.app(context)

            generator.delete_directory(path)
          end

          # @since 1.1.0
          # @api private
          def base_url(context)
            content     = "mount #{context.app.classify}::Application"
            destination = project.environment(context)

            line  = read_matching_line(destination, content)
            *, at = line.split(/at\:[[:space:]]*/)

            at.strip.gsub(/["']*/, "")
          end

          # @since 1.1.0
          # @api private
          def read_matching_line(path, target)
            content = ::File.readlines(path)
            line    = content.find do |l|
              case target
              when String
                l.include?(target)
              when Regexp
                l =~ target
              end
            end

            line or raise ArgumentError.new("Cannot find `#{target}' inside `#{path}'.")
          end
        end
      end
    end
  end
end

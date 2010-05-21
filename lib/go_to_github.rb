module Redcar
  
  class GoToGithub
    
    def self.keymaps
      osx = Keymap.build("main", :osx) do
        link "Cmd+Shift+G", GoToGithub::ShowLineInGithubBlob
        link "Cmd+Shift+B", GoToGithub::ShowLineInGithubBlame
      end
      
      linwin = Keymap.build("main", [:linux, :windows]) do
        link "Ctrl+Shift+G", GoToGithub::ShowLineInGithubBlob
        link "Ctrl+Shift+B", GoToGithub::ShowLineInGithubBlame
      end
      
      [linwin, osx]
    end
    
    def self.menus      
      Menu::Builder.build do
        sub_menu "Plugins" do
          sub_menu "Go to GitHub" do
            item "Show current line in Github!", ShowLineInGithubBlob
            item "Show current line in Github! (Blame)", ShowLineInGithubBlame
            item "Edit plugin", EditGoToGithub
          end
        end
      end
    end

    
    class ShowLineInGithubBlob < Redcar::Command
      def execute                    
        GenerateGithubLink.new(win)
      end
    end
    
    class ShowLineInGithubBlame < Redcar::Command
      def execute
        GenerateGithubLink.new(win, 'blame')
      end
    end
        
    class EditGoToGithub < Redcar::Command
      def execute        
        Project::Manager.open_project_for_path(File.join(Redcar.user_dir, "plugins", "go-to-github"))                
        tab  = Redcar.app.focussed_window.new_tab(Redcar::EditTab)                
        mirror = Project::FileMirror.new(File.join(Redcar.user_dir, "plugins", "go-to-github", "lib", "go_to_github.rb"))
        tab.edit_view.document.mirror = mirror        
        tab.edit_view.reset_undo
        tab.focus
      end
    end
    
    private
    
    class GenerateGithubLink
      
      def initialize(win, type = 'blob')        
        begin
          document = win.focussed_notebook.focussed_tab.document
          current_line = document.cursor_line + 1
          path = Project::Manager.focussed_project.path
          file = document.path[path.size,document.path.size]
          branch = `cd #{path} && git branch --no-color 2> /dev/null`.match(/\*\ (.*)\n/)[1]
          remote = `cd #{path} && git remote`.gsub("\n", "")        
          project_name = `cd #{path} && git config --get remote.#{remote}.url`.match(/github.com[:|\/](.*)\.git\n/)[1]                                        
          
          raise unless branch && remote && project_name
          
          url = "https://github.com/" << project_name << "/" << type << "/" << branch << file << "#L" << current_line.to_s                    
    
          Thread.new do
            case Redcar.platform
            when :osx
              system("open " << url)
            when :linux
              system("x-www-browser " << url)
            when :windows
              system("start " << url)
            end
          end 
          
        rescue
          Application::Dialog.message_box("This project is not Github repository")
        end
      end      
    end
    
  end
  
end
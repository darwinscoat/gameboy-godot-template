# Github Actions for Godot 4 projects guide

# Setup Github actions

- setup exports "Windows", "Linux" and "Web" in godot editor
- copy godot.ci.yml from here : https://github.com/gus3000/godot-build-demo/blob/main/.github/workflows/godot-ci.yml (or search `godot-ci.yml` in this repository) and put it in your project, in `.github/workflows/`. You should adapt the following constants at the top of the file :
    - `GODOT_VERSION` ex: 4.7 or 4.3
    - `EXPORT_NAME` You can set this to whatever you like, this will be used to name the generated files
    - `PROJECT_PATH` the directory containing the `project.godot` file, you probably don't have to change this
- enable Github Pages in github project and configure it the following way :

## How do I enable and configure Github Pages ?
1. Go to your project on github.com
2. Create if needed the `gh-pages` branch :
    1. click on `main` above the file list, you should see a menu pop with the message "Find or create a branch"
    2. type `gh-pages`
    3. click on "Create branch `gh-pages` from `main`"
3. Go to your github project settings
4. In the left menu go to "Pages". You should now be at url like `https://github.com/MY_USERNAME/MY_PROJECT/settings/pages`.
5. Enable Github Pages
6. Set the source to "Github Actions"
7. In Settings > Actions > General, in the category "Workflow permissions" give read and write permissions and save

Now every time you push to your main branch, Github will automatically build and update the web version of your game to the latest changes !

## How do I know the url my latest game is hosted at ?
You can go to your Github project settings > Pages, and you should see at the top of the page : "Your site is live at https://MY_NAME.github.io/MY_PROJECT/", you can save this link, it will always contain the latest version !
Note: you need to have pushed a successful build at least once for this link to appear

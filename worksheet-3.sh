# configure git

git config --global user.name rmuenich
git config --global user.email Rebecca.Muenich@asu.edu
#git commit --no-edit --amend --reset-author

# Link your local repository to the origin repository on GitHub, by
# copying the code shown on your GitHub repo under the heading:
# "…or push an existing repository from the command line"

git remote add origin https://github.com/rmuenich/handouts.git #add remote repo to local repo
git push -u origin master #push local changes/commit up to repo online
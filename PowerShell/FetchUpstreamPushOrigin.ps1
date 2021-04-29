clear-host;
$Location = Get-Location;
Write-Host ("Location $Location");
$CurrentBranch = git rev-parse --abbrev-ref HEAD;
If ($CurrentBranch -ne "master")
{
    write-host "Checking out master branch";
    git checkout master;
}
write-host "Pulling master branch from origin(fork)";
git pull;
write-host "Fetching upstream";
git fetch upstream;
write-host "Merging upstream/master to local master";
git merge upstream/master;
write-host "Pushing local master to origin (fork) master";
git push;
write-host "Checking out develop branch";
git checkout develop;
write-host "Pulling develop branch from origin(fork)";
git pull;
write-host "Fetching upstream";
git fetch upstream;
write-host "Merging upstream/develop to local develop";
git merge upstream/develop;
write-host "Pushing local develop to origin (fork) develop";
git push;
write-host "Checking out master branch";
git checkout master;
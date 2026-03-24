# Machine-specific configuration for work Mac (ubie)
{
  configName,
  currentUser,
  ...
}:
{
  home-manager.users.${currentUser} = _: {
  };
}

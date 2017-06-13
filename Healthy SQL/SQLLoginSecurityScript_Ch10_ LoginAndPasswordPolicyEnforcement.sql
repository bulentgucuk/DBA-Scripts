SELECT 
Name, 
CASE Is_disabled 
WHEN 0 THEN 'No' 
WHEN 1 THEN 'Yes' 
ELSE 'Unknown' 
END as IsLoginDisabled, 
CASE LOGINPROPERTY(name, 'IsLocked') 
WHEN 0 THEN 'No' 
WHEN 1 THEN 'Yes' 
ELSE 'Unknown' 
END as IsAccountLocked, 
CASE LOGINPROPERTY(name, 'IsExpired') 
WHEN 0 THEN 'No' 
WHEN 1 THEN 'Yes' 
ELSE 'Unknown' 
END as IsPasswordExpired, 
CASE LOGINPROPERTY(name, 'IsMustChange') 
WHEN 0 THEN 'No' 
WHEN 1 THEN 'Yes' 
ELSE 'Unknown' 
END as MustChangePasswordOnNextLogin, 
LOGINPROPERTY(name, 'PasswordLastSetTime') as PasswordLastSetDate, 
LOGINPROPERTY(name, 'BadPasswordCount') as CountOfFailedLoginAttempts, 
LOGINPROPERTY(name, 'BadPasswordTime') as LastFailedLoginTime, 
LOGINPROPERTY(name, 'LockoutTime') as LoginLockedOutDateTime, 
LOGINPROPERTY(name, 'DaysUntilExpiration') as 'NoDaysUntilthePasswordExpires' 
From sys.sql_logins 
order by name 
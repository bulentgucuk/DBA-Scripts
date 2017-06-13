

create proc [dbo].uspRandChars
    @len int,
    @min tinyint = 48,
    @range tinyint = 74,
    @exclude varchar(50) = '0:;<=>?@O[]`^\/',
    @output varchar(50) output
as 
    declare @char char
    set @output = ''
 
    while @len > 0 begin
       select @char = char(round(rand() * @range + @min, 0))
       if charindex(@char, @exclude) = 0 begin
           set @output += @char
           set @len = @len - 1
       end
    end
;
GO


declare @newpwd varchar(20)


-- all values between ASCII code 48 - 122 excluding defaults
exec [dbo].uspRandChars @len=8, @output=@newpwd out
select @newpwd


-- all lower case letters excluding o and l
exec [dbo].uspRandChars @len=10, @min=97, @range=25, @exclude='ol', @output=@newpwd out
select @newpwd


-- all upper case letters excluding O
exec [dbo].uspRandChars @len=12, @min=65, @range=25, @exclude='O', @output=@newpwd out
select @newpwd


-- all numbers between 0 and 9
exec [dbo].uspRandChars @len=14, @min=48, @range=9, @exclude='', @output=@newpwd out
select @newpwd
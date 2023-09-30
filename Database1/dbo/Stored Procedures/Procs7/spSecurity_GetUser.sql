
CREATE PROCEDURE dbo.spSecurity_GetUser
 @PageNumber       INT         = NULL -- Current page number
,@PageSize         INT         = NULL -- Total records per page to display
,@Active           bit         = NULL
,@Username         nvarChar(100) = NULL
,@UserId           INT         = NULL 
AS

DECLARE @SQLStr Varchar(max)
DECLARE @StartPosition INT= @PageSize * (@PageNumber - 1);

SET @SQLStr =  '
;With S as (
select User_Id,Active,User_Desc,Username,Is_Role from users_base '

BEGIN
 if(@Username is not null)
	 BEGIN
		 IF(@Active is null)
		 BEGIN
			 SET @SQLStr =  @SQLStr + ' where  Username ='+ '''' + @Username + ''''
		 END
		 ELSE
		 BEGIN
		    SET @SQLStr =  @SQLStr + ' where  active='+cast(@Active as varchar) + 'and Username ='+ '''' + @Username + ''''
		 END
	 END
 ELSE
  BEGIN
	  IF(@Active is not null)
	  BEGIN
		SET @SQLStr =  @SQLStr + ' where  active='+cast(@Active as varchar)
	  END
  END
END


if(@UserId is not null)
BEGIN
  SET @SQLStr =  @SQLStr + ' where  User_Id='+cast(@UserId as nvarchar) 
END


SET @SQLStr =  @SQLStr + '
),S1 as (Select count(0)Total from S)
                    Select *,(Select Total from S1)totalRecords from S'
SET @SQLStr =  @SQLStr + '
			order by Username 
			OFFSET '+cast(@StartPosition as varchar)+' ROWS
			FETCH NEXT '+cast(@PageSize as varchar)+' ROWS ONLY;'
--PRINT @SQLStr
EXEC (@SQLStr)



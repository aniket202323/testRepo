/*
 	 TableId
 	  	 1 = Downtime, KeyId is a Unit Id
 	  	 2 = ScheduleView, KeyId is a Path Id
*/
CREATE FUNCTION dbo.fnBF_CmnGetUserAccessLevel(@KeyId int, 
 	  	  	  	  	 @UserId 	 Int,
 	  	  	  	  	 @TableId Int 
) 
  	  RETURNS  Int
BEGIN
  	  DECLARE @UsersSecurity Int,@Usersecuritygrouplevel Int
  	  SELECT @UsersSecurity = 0
  	  IF NOT EXISTS (SELECT 1 FROM User_Security WHERE User_Id = @UserId  and Group_Id = 1 and Access_Level = 4)
  	  BEGIN
  	    	  IF EXISTS(SELECT 1 FROM Sheets s
  	    	    	    	  Left Join Sheet_Unit su on su.sheet_Id = s.sheet_Id
  	    	    	    	  Left Join Sheet_Paths sp on sp.sheet_Id = s.sheet_Id
  	    	    	    	  join Sheet_Groups sg on s.Sheet_Group_Id = sg.Sheet_Group_Id
  	    	    	    	  WHERE 
 	  	  	  	  s.Is_Active = 1 AND
 	  	  	  	   ((@TableId = 1 and Sheet_Type  = 5  and s.Master_Unit = @KeyId)
  	    	    	    	    	   or (@TableId = 1 and Sheet_Type = 15  and su.PU_Id = @KeyId) 
  	    	    	    	    	   or (@TableId = 1 and Sheet_Type = 28  and su.PU_Id = @KeyId)
  	    	    	    	    	   or (@TableId = 2 and Sheet_Type = 17  and sp.Path_Id = @KeyId)
 	  	  	  	  	   or (@TableId = 4 and Sheet_type in (4,26,29 )and su.PU_Id = @KeyId)
 	  	  	  	  	   
 	  	  	  	  	   )
  	    	    	    	    	  AND s.Group_Id Is Null AND sg.Group_Id Is Null)
  	    	  BEGIN
  	    	    	  Select @UsersSecurity = 3
  	    	  END  	  
  	    	  ELSE
  	    	  BEGIN
  	    	  --get security at display level
  	    	    	  Select @UsersSecurity = Max(u.Access_Level) 
  	    	    	    	    	  from Sheets s
  	    	    	    	    	  Join User_Security u on u.Group_Id = s.Group_Id and u.User_Id = @UserId 
  	    	    	    	    	  Left Join Sheet_Unit su on su.sheet_Id = s.sheet_Id
  	    	    	    	    	  Left Join Sheet_Paths sp on sp.sheet_Id = s.sheet_Id
  	    	    	    	    	  WHERE 
 	  	  	  	  	  s.Is_Active = 1 AND
 	  	  	  	  	  (
 	  	  	  	  	   (@TableId = 1 and Sheet_Type  = 5  and s.Master_Unit = @KeyId)
  	    	    	    	    	    	  or (@TableId = 1 and Sheet_Type = 15  and su.PU_Id = @KeyId) 
  	    	    	    	    	    	  or (@TableId = 1 and Sheet_Type = 28  and su.PU_Id = @KeyId)
  	    	    	    	    	    	  or (@TableId = 2 and Sheet_Type = 17  and sp.Path_Id = @KeyId) 
 	  	  	  	  	  	  or (@TableId = 4 and Sheet_type in (4,26,29 )and su.PU_Id = @KeyId)
 	  	  	  	  	  	  )
  	    	    	  
  	    	    	  --get security at display group level if any other display is configured for same unit
      Select  @Usersecuritygrouplevel =max(u.Access_Level)
  	    	    	    	    	  from Sheets s
  	    	    	    	    	  join Sheet_Groups sg on s.Sheet_Group_Id = sg.Sheet_Group_Id
  	    	    	    	    	  Join User_Security u on u.Group_Id = sg.Group_Id and u.User_Id = @UserId
  	    	    	    	    	  Left Join Sheet_Unit su on su.sheet_Id = s.sheet_Id
  	    	    	    	    	  Left Join Sheet_Paths sp on sp.sheet_Id = s.sheet_Id
  	    	    	    	    	  WHERE  
 	  	  	  	  	  s.Is_Active = 1 AND
 	  	  	  	  	  (
 	  	  	  	  	  
 	  	  	  	  	  (@TableId = 1 and Sheet_Type  = 5  and s.Master_Unit = @KeyId)
  	    	    	    	    	    	  or (@TableId = 1 and Sheet_Type = 15  and su.PU_Id = @KeyId) 
  	    	    	    	    	    	  or (@TableId = 1 and Sheet_Type = 28  and su.PU_Id = @KeyId)
  	    	    	    	    	    	  or (@TableId = 2 and Sheet_Type = 17  and sp.Path_Id = @KeyId)
 	  	  	  	  	  	  or (@TableId = 4 and Sheet_type in (4,26,29 )and su.PU_Id = @KeyId))
  	    	    	    	    	     and s.Group_Id is  null
  	    	  SELECT @UsersSecurity = Coalesce(@UsersSecurity,0)
  	    	  SELECT @Usersecuritygrouplevel = Coalesce(@Usersecuritygrouplevel,0)
  	    	  SELECT @UsersSecurity = CASE when @UsersSecurity > @Usersecuritygrouplevel THEN @UsersSecurity
  	    	    	    	    	    	     WHEN  @UsersSecurity <  @Usersecuritygrouplevel THEN @Usersecuritygrouplevel 
  	    	    	    	    	    	   ELSE @UsersSecurity END
  	    	  END
  	  END
  	  ELSE
  	  BEGIN
  	    	  SELECT @UsersSecurity = 4
  	  END
  	  RETURN @UsersSecurity
END

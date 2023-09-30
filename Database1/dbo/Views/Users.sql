Create View dbo.Users
AS
select c.User_Id,c.Active,C.Is_Role,c.Mixed_Mode_Login,c.Password,c.Role_Based_Security,c.System,c.View_Id,c.WindowsUserInfo,
User_Desc  = coalesce(Description,User_Desc),
Username =  RIGHT(coalesce(d.S95Id,Username),len(coalesce(d.S95Id,Username)) -CHARINDEX('\',coalesce(d.S95Id,Username))),
c.SSOUserId,c.UseSSO
from Users_Base c
Left Join Users_aspect_person b On c.User_Id = b.User_Id
Left Join Person d ON b.Origin1PersonId = d.PersonId

GO
CREATE TRIGGER [dbo].[UsersIns]
 ON  [dbo].[Users]
  INSTEAD OF INSERT
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
BEGIN
 	 SET NOCOUNT ON
 	 DECLARE @PAId 	 Int
 	 INSERT INTO users_base(Active,Is_Role,Mixed_Mode_Login,Password,Role_Based_Security,
 	  	  	  	  	  	  	 System,User_Desc,Username,View_Id,WindowsUserInfo)
  	    	    Select  Coalesce(Active,1),Coalesce(Is_Role,0),Coalesce(Mixed_Mode_Login,1),Coalesce(Password,' '),Coalesce(Role_Based_Security,0),
  	    	  	  	  	 Coalesce(System,0),User_Desc,
  	    	  	  	  	 RIGHT(Username,len(Username) -CHARINDEX('\',Username)),
  	    	  	  	  	 View_Id,WindowsUserInfo
  	    	    From Inserted 
  	 SELECT @PAId = SCOPE_IDENTITY()
 	 IF EXISTS(SELECT 1 FROM Users_base WHERE User_Id = @PAId AND System = 0 AND Active = 1 and Is_Role = 0) AND EXISTS(SELECT 1 FROM Site_Parameters WHERE Parm_Id = 87  and Value = 1 )
  	  	 INSERT INTO PlantAppsSOAPendingTasks(ActualId,TableId)
  	  	  	 VALUES(@PAId,36)
  	  	 
END

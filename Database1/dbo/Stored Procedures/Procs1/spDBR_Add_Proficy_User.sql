Create Procedure dbo.spDBR_Add_Proficy_User
@user_id varchar(30),
@password varchar(30)
AS
 	 declare @id as int
 	 set @id = NULL
 	 set @id = (select user_id from users where username = @user_id)
 	 if (@id is NULL)
 	 begin
 	  	 insert into users (active, system, username, password, is_role, role_based_security) values(1,1,@user_id, @password, 0, 0)
 	  	 set @id = (select scope_identity()) 	  	 
 	  	 select @id as id
 	 end
 	 else
 	 begin
 	  	 select -1 as id
 	 end

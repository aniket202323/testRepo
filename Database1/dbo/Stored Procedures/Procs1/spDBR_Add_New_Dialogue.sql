Create Procedure dbo.spDBR_Add_New_Dialogue
@dialogueName varchar(100),
@url varchar(1000),
@paramcount int
AS 	 
 	 declare @count int, @version int
 	 set @version = 1
 	 set @count = (select count(dashboard_dialogue_name) from dashboard_dialogues where dashboard_dialogue_name = @dialoguename)
 	 if (@count > 0)
 	 begin
 	  	 set @version = (select max(Version) from dashboard_dialogues where dashboard_dialogue_name = @dialoguename)+1
 	 end 	 
 	 declare @id int
 	 insert into dashboard_dialogues (dashboard_dialogue_name, external_address, URL, Parameter_Count,locked, version) 
 	 values(@dialogueName, 1, @url, @paramcount,0, @version)
 	 set @id= (select scope_identity())
 	 select @id as id

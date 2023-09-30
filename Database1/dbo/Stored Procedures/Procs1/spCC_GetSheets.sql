CREATE PROCEDURE dbo.spCC_GetSheets 
  @UserId int,
  @AppVersion nvarchar(10) = NULL
 AS 
Declare @AdminToAdmin int
Select @AdminToAdmin = Count(*) from User_Security where User_Id = @UserId and Group_Id = 1 and Access_Level = 4
Create Table #Sheets (
 Sheet_Group_Id int, 
 Sheet_Group_Desc nvarchar(50), 
 Sheet_Id int, 
 Sheet_Desc nvarchar(50), 
 Sheet_Type int,
 Group_Id int)
Insert Into #Sheets (Sheet_Group_Id, Sheet_Group_Desc, Sheet_Id, Sheet_Desc, Sheet_Type, Group_Id)
  Select g.Sheet_Group_id, Sheet_Group_Desc, s.Sheet_Id, Sheet_Desc, COALESCE(Sheet_Type,1) AS Sheet_Type, Coalesce(s.Group_Id, g.Group_Id) as Group_Id
    From Sheets s 
    Join Sheet_Groups g on g.Sheet_Group_Id = s.Sheet_Group_Id
    Where is_active = 1
      Order by Group_Id
If @AdminToAdmin = 1
  Begin
 	   --Access to All Sheets
 	  	 Select 
 	  	  Sheet_Group_Id , 
 	  	  Sheet_Group_Desc, 
 	  	  Sheet_Id , 
 	  	  Sheet_Desc , 
 	  	  Sheet_Type,
 	  	  App_Id
 	  	   from #Sheets s
 	  	   Join sheet_type st on st.Sheet_Type_Id = s.Sheet_type
        Where st.is_active = 1 and (st.App_Version is NULL or (@AppVersion >= st.App_Version and @AppVersion is not NULL))
 	  	   Order by Sheet_Group_Desc, Sheet_Desc
    Drop Table #Sheets
  End
Else
  Begin
    Create table #Groups (Group_Id int NULL)
    Insert Into #Groups (Group_Id)
      Select DISTINCT us.Group_Id
       From User_Security us
       Where User_Id = @UserId and Access_Level >= 1 
 	  	 Create Table #Sheets2 (
 	  	  Sheet_Group_Id int, 
 	  	  Sheet_Group_Desc nvarchar(50), 
 	  	  Sheet_Id int, 
 	  	  Sheet_Desc nvarchar(50), 
 	  	  Sheet_Type int,
 	  	  Group_Id int)
 	  	 
 	  	 Insert Into #Sheets2 (Sheet_Group_Id, Sheet_Group_Desc, Sheet_Id, Sheet_Desc, Sheet_Type, Group_Id)
 	  	   Select Sheet_Group_id, Sheet_Group_Desc, Sheet_Id, Sheet_Desc, Sheet_Type, Group_Id
 	  	     From #Sheets
 	  	      Where Group_Id is NULL
 	  	 
 	  	 Delete from #Sheets
 	  	   Where Group_Id is NULL
    Delete from #Sheets
      Where Group_Id not in (Select Group_Id from #Groups)
    --Remaining sheets
 	  	 Insert Into #Sheets2 (Sheet_Group_Id, Sheet_Group_Desc, Sheet_Id, Sheet_Desc, Sheet_Type, Group_Id)
 	  	   Select Sheet_Group_id, Sheet_Group_Desc, Sheet_Id, Sheet_Desc, Sheet_Type, Group_Id
 	  	     From #Sheets
 	   --Use has access to these sheets only
 	  	 Select 
 	  	  Sheet_Group_Id , 
 	  	  Sheet_Group_Desc, 
 	  	  Sheet_Id , 
 	  	  Sheet_Desc , 
 	  	  Sheet_Type,
 	  	  App_Id
 	  	   from #Sheets2 s
 	  	   Join sheet_type st on st.Sheet_Type_Id = s.Sheet_type
        Where st.is_active = 1 and (st.App_Version is NULL or (@AppVersion >= st.App_Version and @AppVersion is not NULL))
 	  	   Order by Sheet_Group_Desc, Sheet_Desc
    Drop Table #Sheets
    Drop Table #Sheets2
    Drop Table #Groups
  End

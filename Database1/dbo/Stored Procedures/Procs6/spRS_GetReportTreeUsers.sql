CREATE PROCEDURE dbo.spRS_GetReportTreeUsers
@Template_Id int = null
AS
If @Template_Id is null 
  Begin
    SELECT RTU.User_Id, RTU.User_Rights, RTU.View_Setting, RTU.Report_Tree_Template_Id, RTT.Report_Tree_Template_Name, U.Username, U.User_Desc
    FROM Report_Tree_Users RTU
     Left Join Report_Tree_Templates RTT on RTU.Report_Tree_Template_Id = RTT.Report_Tree_Template_Id
     Left Join Users U on RTU.User_Id = U.User_Id
  End
Else
  Begin
    SELECT RTU.User_Id, RTU.User_Rights, RTU.View_Setting, RTU.Report_Tree_Template_Id, RTT.Report_Tree_Template_Name, U.Username, U.User_Desc
    FROM Report_Tree_Users RTU
     Left Join Report_Tree_Templates RTT on RTU.Report_Tree_Template_Id = RTT.Report_Tree_Template_Id
     Left Join Users U on RTU.User_Id = U.User_Id
     Where  RTU.Report_Tree_Template_Id = @Template_Id
  End

Create Procedure dbo.spAL_EventComponentColumn
  @ComponentId Int
 AS
  -- Select Result Information.
  SELECT Distinct ec.Component_Id,ec.TimeStamp, e.Event_Id,e.Event_Num,e.Event_Status,e.Comment_Id,e.Applied_Product,e.PU_Id,e.Conformance,
 	  	  	  e.Testing_Prct_Complete,Coalesce(e.User_Signoff_Id, 0), Coalesce(e.Approver_User_Id, 0),Coalesce(e.User_Reason_Id, 0),
       Coalesce(e.Approver_Reason_Id, 0), Source_Event_Id = e1.Event_Id, Source_Event_Num = e1.Event_Num
       from Event_Components ec
 	  Join Events e on e.Event_Id = ec.Event_Id
 	  Join Events e1 on e1.Event_Id = ec.Source_Event_Id
 	  WHERE ec.Component_Id = @ComponentId
RETURN(0)

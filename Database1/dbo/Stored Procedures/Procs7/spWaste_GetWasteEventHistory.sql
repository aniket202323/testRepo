
CREATE PROCEDURE dbo.spWaste_GetWasteEventHistory
 @WasteEventId INT
  AS
BEGIN	
	
	    Select  			
                w.WED_Id WasteId,w.Amount WasteAmount,dbo.fnserver_CmnConvertFromDbTime(w.TimeStamp,'UTC') TimeStamp,dbo.fnserver_CmnConvertFromDbTime(w.Entry_On,'UTC')  EntryOn,w.Source_PU_Id SourceUnitId, w.PU_Id MasterUnitId,w.Event_Id AssociatedEventId,e.Event_Num AssociatedEventNum,w.WEFault_Id WasteEventFaultId,w.WET_Id WasteEventTypeId,w.WEMT_Id WasteMeasurementId,wem.Conversion AmountConversionDivisor, w.Cause_Comment_Id CauseCommentId,w.Action_Comment_Id ActionCommentId,w.Action_Level1 ActionLevel1Id,w.Action_Level2 ActionLevel2Id,w.Action_Level3 ActionLevel3Id,w.Action_Level4 ActionLevel4Id,w.Reason_Level1 ReasonLevel1Id,w.Reason_Level2 ReasonLevel2Id,w.Reason_Level3 ReasonLevel3Id,w.Reason_Level4 ReasonLevel4Id,w.User_Id UserId,ub.Username UserName,w.EC_Id EventConfigurationId,null ProductId ,null Confirmed,1 totalRecords

		 	            from
		                Waste_Event_Detail_History w
		                    LEFT JOIN Events e WITH (nolock) on e.Event_Id = w.Event_Id
		                    LEFT JOIN Waste_Event_Fault wef WITH (nolock) on wef.WEFault_Id = w.WEFault_Id
		                    LEFT JOIN Waste_Event_Type wet WITH (nolock) on wet.WET_Id = w.WET_Id
		                    LEFT JOIN Waste_Event_Meas wem WITH (nolock) on wem.WEMT_Id = w.WEMT_Id
		                    LEFT JOIN Users_Base ub WITH (nolock) on ub.User_Id = w.User_Id
		            Where w.WED_Id =@WasteEventId

    order by w.Entry_On 			
END
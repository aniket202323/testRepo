CREATE view SDK_V_PAESignature
as
select
ESignature.Signature_Id as Id,
ESignature.Perform_User_Id as OperatorId,
opu.Username as Operator,
ESignature.Perform_Node as OperatorLocation,
ESignature.Perform_Time as OperatorTime,
ESignature.Perform_Comment_Id as OperatorCommentId,
opc.Comment_Text as OperatorCommentText,
ESignature.Verify_User_Id as ApproverId,
apu.Username as Approver,
ESignature.Verify_Node as ApproverLocation,
ESignature.Verify_Time as ApproverTime,
ESignature.Verify_Comment_Id as ApproverCommentId,
apc.Comment_Text as ApproverCommentText,
ESignature.Perform_Reason_Id as OperatorReasonId,
opr.Event_Reason_Name as OperatorReason,
ESignature.Verify_Reason_Id as ApproverReasonId,
apr.Event_Reason_Name as ApproverReason
FROM ESignature
 LEFT JOIN Users opu ON opu.User_Id = ESignature.Perform_User_Id
 LEFT JOIN Comments opc ON opc.Comment_Id = ESignature.Perform_Comment_Id
 LEFT JOIN Event_Reasons opr ON opr.Event_Reason_Id = ESignature.Perform_Reason_Id
 LEFT JOIN Users apu ON apu.User_Id = ESignature.Verify_User_Id
 LEFT JOIN Comments apc ON apc.Comment_Id = ESignature.Verify_Comment_Id
 LEFT JOIN Event_Reasons apr ON apr.Event_Reason_Id = ESignature.Verify_Reason_Id

CREATE TABLE [dbo].[Event_History] (
    [Event_History_Id]       BIGINT         IDENTITY (1, 1) NOT NULL,
    [Event_Num]              VARCHAR (50)   NULL,
    [PU_Id]                  INT            NULL,
    [TimeStamp]              DATETIME       NULL,
    [Confirmed]              BIT            NULL,
    [Applied_Product]        INT            NULL,
    [Approver_Reason_Id]     INT            NULL,
    [Approver_User_Id]       INT            NULL,
    [BOM_Formulation_Id]     BIGINT         NULL,
    [Comment_Id]             INT            NULL,
    [Conformance]            TINYINT        NULL,
    [Consumed_Timestamp]     DATETIME       NULL,
    [Entry_On]               DATETIME       NULL,
    [Event_Status]           INT            NULL,
    [Event_Subtype_Id]       INT            NULL,
    [Extended_Info]          VARCHAR (255)  NULL,
    [Second_User_Id]         INT            NULL,
    [Signature_Id]           INT            NULL,
    [Source_Event]           INT            NULL,
    [Start_Time]             DATETIME       NULL,
    [Testing_Prct_Complete]  TINYINT        NULL,
    [User_Id]                INT            NULL,
    [User_Reason_Id]         INT            NULL,
    [User_Signoff_Id]        INT            NULL,
    [Testing_Status]         INT            NULL,
    [Event_Id]               INT            NULL,
    [Modified_On]            DATETIME       NULL,
    [DBTT_Id]                TINYINT        NULL,
    [Column_Updated_BitMask] VARCHAR (15)   NULL,
    [Lot_Identifier]         NVARCHAR (100) NULL,
    [Operation_Name]         NVARCHAR (100) NULL,
    CONSTRAINT [Event_History_PK_Id] PRIMARY KEY NONCLUSTERED ([Event_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [EventHistory_IX_EventIdModifiedOn]
    ON [dbo].[Event_History]([Event_Id] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[Event_History_ERP_Ins]
 ON  [dbo].[Event_History]
  For INSERT
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 	 If (select count(*) from subscription_trigger Where Table_Id = 1) > 0
 	   Begin
 	  	 if (select count(*) from subscription_trigger where table_id = 1 and Key_id is null) > 0 	  	  	  	  	      -- 	 
 	  	   Begin 	  	  	  	  	  	  	  	  	 --
 	  	  	 Insert Into ERP_Transactions (ActualId,DBTT_Id,Table_Id,Entry_On) 
 	  	  	  	 Select Event_Id,DBTT_Id,1,Modified_On
 	  	  	  	  	   From Inserted i
 	  	   End 
 	  	 else
 	  	   Begin
 	  	  	 Insert Into ERP_Transactions (ActualId,DBTT_Id,Table_Id,Entry_On)
 	  	  	   Select Event_Id,DBTT_Id,1,Modified_On
 	  	    	  	 From Inserted i
 	  	  	  	 Join Subscription_Trigger s on i.pu_Id = s.Key_Id
 	  	   End
 	   End

GO
CREATE TRIGGER [dbo].[Event_History_UpdDel]
 ON  [dbo].[Event_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) --DataPurge
BEGIN
 	 DELETE Event_History
 	 FROM Event_History a 
 	 JOIN  Deleted b on b.Event_Id = a.Event_Id
END

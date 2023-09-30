CREATE TABLE [dbo].[Email_Recipients] (
    [ER_Id]                INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [ER_Address]           VARCHAR (70)  NOT NULL,
    [ER_Desc]              VARCHAR (100) NOT NULL,
    [Is_Active]            BIT           CONSTRAINT [EmailRecipients_DF_IsActive] DEFAULT ((1)) NULL,
    [Standard_Header_Mode] TINYINT       NULL,
    CONSTRAINT [EmailRecipients_PK_ERId] PRIMARY KEY CLUSTERED ([ER_Id] ASC)
);


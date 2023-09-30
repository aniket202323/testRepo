CREATE TABLE [dbo].[Email_Messages] (
    [EM_Id]          INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [EG_Id]          INT            NULL,
    [EM_Attachments] VARCHAR (1000) NULL,
    [EM_Content]     TEXT           NULL,
    [EM_Processed]   TINYINT        CONSTRAINT [EmailMessages_DF_EMProcessed] DEFAULT ((0)) NULL,
    [EM_Subject]     VARCHAR (2000) NULL,
    [Submitted_On]   DATETIME       NULL,
    [Key_Id]         INT            NULL,
    [Table_Id]       INT            NULL,
    CONSTRAINT [EmailMessages_PK_EMId] PRIMARY KEY CLUSTERED ([EM_Id] ASC),
    CONSTRAINT [EmailMessages_FK_EGId] FOREIGN KEY ([EG_Id]) REFERENCES [dbo].[Email_Groups] ([EG_Id])
);


GO
CREATE NONCLUSTERED INDEX [EmailMessages_IDX_EMProcessed]
    ON [dbo].[Email_Messages]([EM_Processed] ASC);


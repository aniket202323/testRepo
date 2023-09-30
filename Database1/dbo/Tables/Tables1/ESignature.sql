CREATE TABLE [dbo].[ESignature] (
    [Signature_Id]       INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Extended_Info]      VARCHAR (255)  NULL,
    [Perform_Comment_Id] INT            NULL,
    [Perform_Node]       VARCHAR (50)   NULL,
    [Perform_Reason_Id]  INT            NULL,
    [Perform_Time]       DATETIME       NULL,
    [Perform_Time_MS]    SMALLINT       CONSTRAINT [Alarms_DF_PerformTimeMs] DEFAULT ((0)) NULL,
    [Perform_User_Id]    INT            NULL,
    [Verify_Comment_Id]  INT            NULL,
    [Verify_Node]        VARCHAR (50)   NULL,
    [Verify_Reason_Id]   INT            NULL,
    [Verify_Time]        DATETIME       NULL,
    [Verify_Time_MS]     SMALLINT       CONSTRAINT [Alarms_DF_VerifyTimeMs] DEFAULT ((0)) NULL,
    [Verify_User_Id]     INT            NULL,
    [Signing_Context]    NVARCHAR (MAX) NULL,
    CONSTRAINT [ESignature_PK_SignatureId] PRIMARY KEY NONCLUSTERED ([Signature_Id] ASC),
    CONSTRAINT [ESignature_FK_UserId] FOREIGN KEY ([Verify_User_Id]) REFERENCES [dbo].[Users_Base] ([User_Id]),
    CONSTRAINT [ESignaturePUserId_FK_UserId] FOREIGN KEY ([Perform_User_Id]) REFERENCES [dbo].[Users_Base] ([User_Id])
);


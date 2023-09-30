CREATE TABLE [dbo].[new_test_history] (
    [Canceled]               BIT           NULL,
    [Result_On]              DATETIME2 (3) NULL,
    [Entry_On]               DATETIME2 (3) NULL,
    [Second_User_Id]         INT           NULL,
    [Entry_By]               INT           NULL,
    [Comment_Id]             INT           NULL,
    [Array_Id]               INT           NULL,
    [Test_Id]                INT           NULL,
    [Event_Id]               INT           NULL,
    [Var_Id]                 INT           NULL,
    [Locked]                 TINYINT       NULL,
    [Result]                 VARCHAR (25)  NULL,
    [Modified_On]            DATETIME2 (3) NULL,
    [DBTT_Id]                TINYINT       NULL,
    [Column_Updated_BitMask] VARCHAR (15)  NULL,
    [Signature_Id]           INT           NULL
);


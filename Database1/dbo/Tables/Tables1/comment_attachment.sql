CREATE TABLE [dbo].[comment_attachment] (
    [comment_id]  BIGINT         NOT NULL,
    [attachments] NVARCHAR (MAX) NOT NULL,
    PRIMARY KEY CLUSTERED ([comment_id] ASC),
    UNIQUE NONCLUSTERED ([comment_id] ASC)
);


"""add book foreign key delete actions

Revision ID: b4e6f8a2c9d1
Revises: 9b1c2d3e4f60
Create Date: 2026-07-28 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op


revision: str = "b4e6f8a2c9d1"
down_revision: Union[str, Sequence[str], None] = "9b1c2d3e4f60"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.drop_constraint("reading_activity_book_id_fkey", "reading_activity", type_="foreignkey")
    op.create_foreign_key(
        "reading_activity_book_id_fkey",
        "reading_activity",
        "books",
        ["book_id"],
        ["id"],
        ondelete="CASCADE",
    )

    op.drop_constraint("book_embeddings_book_id_fkey", "book_embeddings", type_="foreignkey")
    op.create_foreign_key(
        "book_embeddings_book_id_fkey",
        "book_embeddings",
        "books",
        ["book_id"],
        ["id"],
        ondelete="SET NULL",
    )

    op.drop_constraint("recommendation_feedback_book_id_fkey", "recommendation_feedback", type_="foreignkey")
    op.create_foreign_key(
        "recommendation_feedback_book_id_fkey",
        "recommendation_feedback",
        "books",
        ["book_id"],
        ["id"],
        ondelete="SET NULL",
    )


def downgrade() -> None:
    op.drop_constraint("recommendation_feedback_book_id_fkey", "recommendation_feedback", type_="foreignkey")
    op.create_foreign_key(
        "recommendation_feedback_book_id_fkey",
        "recommendation_feedback",
        "books",
        ["book_id"],
        ["id"],
    )

    op.drop_constraint("book_embeddings_book_id_fkey", "book_embeddings", type_="foreignkey")
    op.create_foreign_key(
        "book_embeddings_book_id_fkey",
        "book_embeddings",
        "books",
        ["book_id"],
        ["id"],
    )

    op.drop_constraint("reading_activity_book_id_fkey", "reading_activity", type_="foreignkey")
    op.create_foreign_key(
        "reading_activity_book_id_fkey",
        "reading_activity",
        "books",
        ["book_id"],
        ["id"],
    )

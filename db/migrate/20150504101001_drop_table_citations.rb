class DropTableCitations < ActiveRecord::Migration[4.2]
  def change
    drop_table :citations
  end
end

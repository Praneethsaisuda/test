/*
  # Real Estate Platform Database Schema

  ## Overview
  Creates a comprehensive database structure for a real estate buying and selling platform.

  ## New Tables
  
  ### `properties`
  - `id` (uuid, primary key) - Unique property identifier
  - `title` (text) - Property title/headline
  - `description` (text) - Detailed property description
  - `property_type` (text) - Type: house, apartment, condo, land, commercial
  - `listing_type` (text) - For sale or for rent
  - `price` (numeric) - Property price
  - `bedrooms` (integer) - Number of bedrooms
  - `bathrooms` (numeric) - Number of bathrooms
  - `square_feet` (integer) - Property size in sq ft
  - `address` (text) - Street address
  - `city` (text) - City name
  - `state` (text) - State/province
  - `zip_code` (text) - Postal code
  - `country` (text) - Country
  - `latitude` (numeric) - GPS latitude
  - `longitude` (numeric) - GPS longitude
  - `year_built` (integer) - Year of construction
  - `status` (text) - active, pending, sold, rented
  - `featured` (boolean) - Featured listing flag
  - `agent_id` (uuid) - Reference to agent/seller
  - `views_count` (integer) - Number of views
  - `created_at` (timestamptz) - Creation timestamp
  - `updated_at` (timestamptz) - Last update timestamp

  ### `property_images`
  - `id` (uuid, primary key)
  - `property_id` (uuid) - Reference to properties
  - `image_url` (text) - Image URL
  - `is_primary` (boolean) - Main property image
  - `display_order` (integer) - Sort order
  - `created_at` (timestamptz)

  ### `property_features`
  - `id` (uuid, primary key)
  - `property_id` (uuid) - Reference to properties
  - `feature_name` (text) - Feature name (pool, garage, etc.)
  - `feature_value` (text) - Feature value/description

  ### `agents`
  - `id` (uuid, primary key)
  - `user_id` (uuid) - Reference to auth.users
  - `full_name` (text)
  - `email` (text)
  - `phone` (text)
  - `bio` (text)
  - `avatar_url` (text)
  - `license_number` (text)
  - `rating` (numeric)
  - `total_sales` (integer)
  - `created_at` (timestamptz)

  ### `saved_properties`
  - `id` (uuid, primary key)
  - `user_id` (uuid) - Reference to auth.users
  - `property_id` (uuid) - Reference to properties
  - `created_at` (timestamptz)

  ### `inquiries`
  - `id` (uuid, primary key)
  - `property_id` (uuid) - Reference to properties
  - `name` (text)
  - `email` (text)
  - `phone` (text)
  - `message` (text)
  - `status` (text) - new, contacted, closed
  - `created_at` (timestamptz)

  ## Security
  - Enable RLS on all tables
  - Public read access for active properties
  - Authenticated users can save properties
  - Only agents can create/edit their properties
  - Users can view their own saved properties and inquiries
*/

-- Create properties table
CREATE TABLE IF NOT EXISTS properties (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text NOT NULL,
  property_type text NOT NULL DEFAULT 'house',
  listing_type text NOT NULL DEFAULT 'sale',
  price numeric NOT NULL,
  bedrooms integer DEFAULT 0,
  bathrooms numeric DEFAULT 0,
  square_feet integer,
  address text NOT NULL,
  city text NOT NULL,
  state text NOT NULL,
  zip_code text,
  country text DEFAULT 'USA',
  latitude numeric,
  longitude numeric,
  year_built integer,
  status text DEFAULT 'active',
  featured boolean DEFAULT false,
  agent_id uuid,
  views_count integer DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create property_images table
CREATE TABLE IF NOT EXISTS property_images (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id uuid REFERENCES properties(id) ON DELETE CASCADE,
  image_url text NOT NULL,
  is_primary boolean DEFAULT false,
  display_order integer DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

-- Create property_features table
CREATE TABLE IF NOT EXISTS property_features (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id uuid REFERENCES properties(id) ON DELETE CASCADE,
  feature_name text NOT NULL,
  feature_value text,
  created_at timestamptz DEFAULT now()
);

-- Create agents table
CREATE TABLE IF NOT EXISTS agents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name text NOT NULL,
  email text NOT NULL,
  phone text,
  bio text,
  avatar_url text,
  license_number text,
  rating numeric DEFAULT 0,
  total_sales integer DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

-- Create saved_properties table
CREATE TABLE IF NOT EXISTS saved_properties (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  property_id uuid REFERENCES properties(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, property_id)
);

-- Create inquiries table
CREATE TABLE IF NOT EXISTS inquiries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id uuid REFERENCES properties(id) ON DELETE CASCADE,
  name text NOT NULL,
  email text NOT NULL,
  phone text,
  message text NOT NULL,
  status text DEFAULT 'new',
  created_at timestamptz DEFAULT now()
);

-- Enable Row Level Security
ALTER TABLE properties ENABLE ROW LEVEL SECURITY;
ALTER TABLE property_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE property_features ENABLE ROW LEVEL SECURITY;
ALTER TABLE agents ENABLE ROW LEVEL SECURITY;
ALTER TABLE saved_properties ENABLE ROW LEVEL SECURITY;
ALTER TABLE inquiries ENABLE ROW LEVEL SECURITY;

-- Properties policies
CREATE POLICY "Anyone can view active properties"
  ON properties FOR SELECT
  USING (status = 'active');

CREATE POLICY "Agents can insert their own properties"
  ON properties FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM agents
      WHERE agents.user_id = auth.uid()
      AND agents.id = agent_id
    )
  );

CREATE POLICY "Agents can update their own properties"
  ON properties FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM agents
      WHERE agents.user_id = auth.uid()
      AND agents.id = agent_id
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM agents
      WHERE agents.user_id = auth.uid()
      AND agents.id = agent_id
    )
  );

CREATE POLICY "Agents can delete their own properties"
  ON properties FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM agents
      WHERE agents.user_id = auth.uid()
      AND agents.id = agent_id
    )
  );

-- Property images policies
CREATE POLICY "Anyone can view property images"
  ON property_images FOR SELECT
  USING (true);

CREATE POLICY "Agents can manage their property images"
  ON property_images FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM properties p
      JOIN agents a ON p.agent_id = a.id
      WHERE p.id = property_images.property_id
      AND a.user_id = auth.uid()
    )
  );

-- Property features policies
CREATE POLICY "Anyone can view property features"
  ON property_features FOR SELECT
  USING (true);

CREATE POLICY "Agents can manage their property features"
  ON property_features FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM properties p
      JOIN agents a ON p.agent_id = a.id
      WHERE p.id = property_features.property_id
      AND a.user_id = auth.uid()
    )
  );

-- Agents policies
CREATE POLICY "Anyone can view agents"
  ON agents FOR SELECT
  USING (true);

CREATE POLICY "Users can create their agent profile"
  ON agents FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own agent profile"
  ON agents FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Saved properties policies
CREATE POLICY "Users can view their saved properties"
  ON saved_properties FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can save properties"
  ON saved_properties FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can remove saved properties"
  ON saved_properties FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- Inquiries policies
CREATE POLICY "Anyone can create inquiries"
  ON inquiries FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Agents can view inquiries for their properties"
  ON inquiries FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM properties p
      JOIN agents a ON p.agent_id = a.id
      WHERE p.id = inquiries.property_id
      AND a.user_id = auth.uid()
    )
  );

CREATE POLICY "Agents can update inquiry status"
  ON inquiries FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM properties p
      JOIN agents a ON p.agent_id = a.id
      WHERE p.id = inquiries.property_id
      AND a.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM properties p
      JOIN agents a ON p.agent_id = a.id
      WHERE p.id = inquiries.property_id
      AND a.user_id = auth.uid()
    )
  );

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_properties_status ON properties(status);
CREATE INDEX IF NOT EXISTS idx_properties_city ON properties(city);
CREATE INDEX IF NOT EXISTS idx_properties_property_type ON properties(property_type);
CREATE INDEX IF NOT EXISTS idx_properties_listing_type ON properties(listing_type);
CREATE INDEX IF NOT EXISTS idx_properties_featured ON properties(featured);
CREATE INDEX IF NOT EXISTS idx_property_images_property_id ON property_images(property_id);
CREATE INDEX IF NOT EXISTS idx_property_features_property_id ON property_features(property_id);
CREATE INDEX IF NOT EXISTS idx_saved_properties_user_id ON saved_properties(user_id);
CREATE INDEX IF NOT EXISTS idx_inquiries_property_id ON inquiries(property_id);
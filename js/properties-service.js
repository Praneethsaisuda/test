import { supabase } from './supabase-client.js'

export const propertiesService = {
  async getProperties(filters = {}) {
    let query = supabase
      .from('properties')
      .select(`
        *,
        property_images(id, image_url, is_primary),
        property_features(feature_name, feature_value),
        agents(full_name, rating, total_sales)
      `)
      .eq('status', 'active')

    if (filters.city) {
      query = query.ilike('city', `%${filters.city}%`)
    }

    if (filters.propertyType) {
      query = query.eq('property_type', filters.propertyType)
    }

    if (filters.minPrice) {
      query = query.gte('price', filters.minPrice)
    }

    if (filters.maxPrice) {
      query = query.lte('price', filters.maxPrice)
    }

    if (filters.bedrooms) {
      query = query.gte('bedrooms', filters.bedrooms)
    }

    if (filters.listingType) {
      query = query.eq('listing_type', filters.listingType)
    }

    if (filters.featured) {
      query = query.eq('featured', true)
    }

    const { data, error } = await query.limit(20)

    if (error) {
      console.error('Error fetching properties:', error)
      return []
    }

    return data || []
  },

  async getPropertyById(id) {
    const { data, error } = await supabase
      .from('properties')
      .select(`
        *,
        property_images(id, image_url, is_primary, display_order),
        property_features(feature_name, feature_value),
        agents(full_name, email, phone, bio, avatar_url, rating, total_sales)
      `)
      .eq('id', id)
      .maybeSingle()

    if (error) {
      console.error('Error fetching property:', error)
      return null
    }

    return data
  },

  async getFeaturedProperties() {
    const { data, error } = await supabase
      .from('properties')
      .select(`
        *,
        property_images(image_url, is_primary),
        agents(full_name, rating)
      `)
      .eq('status', 'active')
      .eq('featured', true)
      .limit(6)

    if (error) {
      console.error('Error fetching featured properties:', error)
      return []
    }

    return data || []
  },

  async searchProperties(query) {
    const { data, error } = await supabase
      .from('properties')
      .select(`
        *,
        property_images(image_url, is_primary)
      `)
      .eq('status', 'active')
      .or(`title.ilike.%${query}%,description.ilike.%${query}%,city.ilike.%${query}%`)
      .limit(20)

    if (error) {
      console.error('Error searching properties:', error)
      return []
    }

    return data || []
  },

  async createInquiry(inquiry) {
    const { error } = await supabase
      .from('inquiries')
      .insert([inquiry])

    if (error) {
      console.error('Error creating inquiry:', error)
      return false
    }

    return true
  },

  async saveProperty(userId, propertyId) {
    const { error } = await supabase
      .from('saved_properties')
      .insert([{ user_id: userId, property_id: propertyId }])

    if (error) {
      if (error.code !== 'PGRST116') {
        console.error('Error saving property:', error)
        return false
      }
    }

    return true
  },

  async removeSavedProperty(userId, propertyId) {
    const { error } = await supabase
      .from('saved_properties')
      .delete()
      .eq('user_id', userId)
      .eq('property_id', propertyId)

    if (error) {
      console.error('Error removing saved property:', error)
      return false
    }

    return true
  },

  async getSavedProperties(userId) {
    const { data, error } = await supabase
      .from('saved_properties')
      .select(`
        property_id,
        properties(
          *,
          property_images(image_url, is_primary)
        )
      `)
      .eq('user_id', userId)

    if (error) {
      console.error('Error fetching saved properties:', error)
      return []
    }

    return data?.map(item => item.properties) || []
  }
}

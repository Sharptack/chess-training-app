import '../models/campaign.dart';
import '../sources/local/asset_source.dart';
import '../../core/errors/failure.dart';
import '../../core/utils/result.dart';

class CampaignRepository {
  final AssetSource _assets;

  const CampaignRepository({AssetSource? assets})
      : _assets = assets ?? const AssetSource();

  /// Load a campaign JSON by ID
  Future<Result<Campaign>> getCampaignById(String id) async {
    final normalized = id.startsWith('campaign_') ? id : 'campaign_${id.padLeft(2, '0')}';
    final path = 'assets/data/campaigns/$normalized.json';

    final jsonRes = await _assets.readJson(path);
    if (jsonRes.isError) return Result.error(jsonRes.failure!);

    try {
      final campaignJson = jsonRes.data!;
      final campaign = Campaign.fromJson(campaignJson);
      return Result.success(campaign);
    } on ArgumentError catch (e) {
      return Result.error(ParseFailure(
          'Missing required fields in campaign JSON',
          details: e.message.toString()));
    } catch (e) {
      return Result.error(UnexpectedFailure(
          'Failed to parse Campaign', details: e.toString()));
    }
  }

  /// Load all campaigns from the index
  Future<Result<List<Campaign>>> getAllCampaigns() async {
    final path = 'assets/data/campaigns/index.json';

    final jsonRes = await _assets.readJson(path);
    if (jsonRes.isError) return Result.error(jsonRes.failure!);

    try {
      final indexJson = jsonRes.data!;
      final List<Campaign> campaigns = [];

      // The index contains campaign IDs, load each one
      for (final entry in indexJson.entries) {
        final campaignId = entry.key;
        final campaignResult = await getCampaignById(campaignId);

        if (campaignResult.isSuccess) {
          campaigns.add(campaignResult.data!);
        }
        // Skip campaigns that fail to load (for now)
      }

      return Result.success(campaigns);
    } catch (e) {
      return Result.error(UnexpectedFailure(
          'Failed to load campaigns', details: e.toString()));
    }
  }
}
